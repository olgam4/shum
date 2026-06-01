mod navidrome;
mod storage;

use navidrome::{
    CacheProgress, ConnectionStatus, NavidromeClient, NavidromeConfig,
    SearchResult,
};
use std::sync::{Arc, Mutex};
use storage::{load_config, save_config, LibraryDb};
use tauri::{Emitter, Manager};
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct SyncResult {
    artists: Vec<navidrome::LibraryArtist>,
    albums: Vec<navidrome::LibraryAlbum>,
    songs: Vec<navidrome::LibrarySong>,
    artist_count: u32,
    album_count: u32,
    song_count: u32,
    last_sync: Option<String>,
}

fn chrono_now() -> String {
    use std::time::SystemTime;
    let ts = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    format!("{}", ts)
}

// ─── Navidrome Commands ───

struct NavidromeState {
    client: Option<NavidromeClient>,
}

#[tauri::command]
async fn connect_server(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
    app_handle: tauri::AppHandle,
    server_url: String,
    username: String,
    password: String,
) -> Result<ConnectionStatus, String> {
    let password_hex = format!("enc:{}", hex::encode(password.as_bytes()));

    let config = NavidromeConfig {
        server_url: server_url.clone(),
        username: username.clone(),
        password_hex: password_hex.clone(),
    };

    let client = NavidromeClient::new(config.clone());

    match client.ping().await {
        Ok((server_type, server_version)) => {
            let mut ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
            ns.client = Some(client);

            let app_dir = app_handle.path().app_data_dir().map_err(|e| e.to_string())?;
            save_config(&app_dir, &config)?;

            Ok(ConnectionStatus {
                connected: true,
                server_name: Some(server_type),
                server_version: Some(server_version),
                error: None,
            })
        }
        Err(e) => Ok(ConnectionStatus {
            connected: false,
            server_name: None,
            server_version: None,
            error: Some(e),
        }),
    }
}

#[tauri::command]
fn disconnect(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
    app_handle: tauri::AppHandle,
) -> Result<(), String> {
    let mut ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
    ns.client = None;

    let app_dir = app_handle.path().app_data_dir().map_err(|e| e.to_string())?;
    if let Err(e) = std::fs::remove_file(app_dir.join("shum_config.enc")) {
        log::warn!("[disconnect] could not remove config file: {}", e);
    }

    Ok(())
}

#[tauri::command]
fn get_connection_status(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
) -> Result<ConnectionStatus, String> {
    let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
    Ok(ConnectionStatus {
        connected: ns.client.is_some(),
        server_name: None,
        server_version: None,
        error: None,
    })
}

#[tauri::command]
async fn sync_library(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
    lib_db: tauri::State<'_, Arc<LibraryDb>>,
) -> Result<SyncResult, String> {
    let client = {
        let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
        ns.client.clone().ok_or("not connected")?
    };

    lib_db.clear()?;

    let batch_size: u32 = 500;
    let mut song_offset: u32 = 0;
    let mut album_offset: u32 = 0;
    let mut artist_offset: u32 = 0;

    loop {
        let results = client
            .search3("", artist_offset, batch_size, album_offset, batch_size, song_offset, batch_size)
            .await?;

        if results.songs.is_empty() && results.albums.is_empty() && results.artists.is_empty() {
            break;
        }

        for song in &results.songs {
            lib_db.insert_song(song)?;
        }
        for album in &results.albums {
            lib_db.insert_album(album)?;
        }
        for artist in &results.artists {
            lib_db.insert_artist(artist)?;
        }

        song_offset += batch_size;
        album_offset += batch_size;
        artist_offset += batch_size;
    }

    let now = chrono_now();
    lib_db.set_last_sync(&now)?;

    Ok(SyncResult {
        artists: lib_db.get_all_artists(),
        albums: lib_db.get_all_albums(),
        songs: lib_db.get_all_songs(),
        artist_count: lib_db.artist_count(),
        album_count: lib_db.album_count(),
        song_count: lib_db.song_count(),
        last_sync: Some(now),
    })
}

#[tauri::command]
async fn search_library(
    lib_db: tauri::State<'_, Arc<LibraryDb>>,
    query: String,
) -> Result<SearchResult, String> {
    if query.is_empty() {
        Ok(SearchResult {
            artists: lib_db.get_all_artists(),
            albums: lib_db.get_all_albums(),
            songs: lib_db.get_all_songs(),
        })
    } else {
        Ok(SearchResult {
            artists: lib_db.search_artists(&query),
            albums: lib_db.search_albums(&query),
            songs: lib_db.search_songs(&query),
        })
    }
}

#[tauri::command]
fn get_stream_url(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
    id: String,
) -> Result<String, String> {
    let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
    let client = ns.client.as_ref().ok_or("not connected")?;
    Ok(client.stream_url(&id))
}

#[tauri::command]
fn get_cover_art_url(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
    id: String,
) -> Result<String, String> {
    let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
    let client = ns.client.as_ref().ok_or("not connected")?;
    Ok(client.cover_art_url(&id))
}

#[tauri::command]
async fn cache_song(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
    app_handle: tauri::AppHandle,
    id: String,
) -> Result<CacheProgress, String> {
    let client = {
        let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
        ns.client.clone().ok_or("not connected")?
    };

    let app_dir = app_handle.path().app_data_dir().map_err(|e| e.to_string())?;
    let cache_dir = LibraryDb::get_cache_dir(&app_dir);
    std::fs::create_dir_all(&cache_dir).map_err(|e| e.to_string())?;

    let local_path = cache_dir.join(format!("{}", id));
    let path_str = local_path.to_string_lossy().to_string();

    let progress = CacheProgress {
        song_id: id.clone(),
        status: "downloading".to_string(),
        local_path: None,
    };
    let _ = app_handle.emit("shum:cache-progress", &progress);

    match client.download_song(&id, &path_str).await {
        Ok(p) => {
            let done = CacheProgress {
                song_id: id,
                status: "complete".to_string(),
                local_path: Some(p),
            };
            let _ = app_handle.emit("shum:cache-progress", &done);
            Ok(done)
        }
        Err(e) => {
            let failed = CacheProgress {
                song_id: id,
                status: "error".to_string(),
                local_path: None,
            };
            let _ = app_handle.emit("shum:cache-progress", &failed);
            Err(e)
        }
    }
}

#[tauri::command]
fn get_cached_song_path(
    app_handle: tauri::AppHandle,
    id: String,
) -> Result<Option<String>, String> {
    let app_dir = app_handle.path().app_data_dir().map_err(|e| e.to_string())?;
    let cache_dir = LibraryDb::get_cache_dir(&app_dir);
    let path = cache_dir.join(&id);
    if path.exists() {
        Ok(Some(path.to_string_lossy().to_string()))
    } else {
        Ok(None)
    }
}

// ─── Startup Hydration ───

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct StartupState {
    connection_status: ConnectionStatus,
    library: Option<SyncResult>,
}

#[tauri::command]
async fn startup_hydrate(
    nav_state: tauri::State<'_, Arc<Mutex<NavidromeState>>>,
    lib_db: tauri::State<'_, Arc<LibraryDb>>,
    app_handle: tauri::AppHandle,
) -> Result<StartupState, String> {
    let app_dir = app_handle.path().app_data_dir().map_err(|e| e.to_string())?;

    let connection_status = if let Some(config) = load_config(&app_dir) {
        log::info!("[SHUM] startup hydrate: attempting reconnect to {}", config.server_url);
        let client = NavidromeClient::new(config);
        match client.ping().await {
            Ok((server_type, server_version)) => {
                let mut ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
                ns.client = Some(client);
                ConnectionStatus {
                    connected: true,
                    server_name: Some(server_type),
                    server_version: Some(server_version),
                    error: None,
                }
            }
            Err(e) => ConnectionStatus {
                connected: false,
                server_name: None,
                server_version: None,
                error: Some(e),
            },
        }
    } else {
        ConnectionStatus {
            connected: false,
            server_name: None,
            server_version: None,
            error: None,
        }
    };

    let library = if connection_status.connected && lib_db.song_count() > 0 {
        Some(SyncResult {
            artists: lib_db.get_all_artists(),
            albums: lib_db.get_all_albums(),
            songs: lib_db.get_all_songs(),
            artist_count: lib_db.artist_count(),
            album_count: lib_db.album_count(),
            song_count: lib_db.song_count(),
            last_sync: lib_db.get_last_sync(),
        })
    } else {
        None
    };

    Ok(StartupState {
        connection_status,
        library,
    })
}

// ─── Entry Point ───

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    log::info!("[SHUM] starting Tauri v2 mobile backend");

    let nav_state = Arc::new(Mutex::new(NavidromeState { client: None }));

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_haptics::init())
        .plugin(tauri_plugin_native_audio::init())
        .manage(nav_state)
        .invoke_handler(tauri::generate_handler![
            connect_server,
            disconnect,
            get_connection_status,
            sync_library,
            search_library,
            get_stream_url,
            get_cover_art_url,
            cache_song,
            get_cached_song_path,
            startup_hydrate,
        ])
        .setup(move |app| {
            log::info!("[SHUM] Tauri v2 mobile backend initialised");

            let app_dir = app.path().app_data_dir().map_err(|e| e.to_string()).unwrap_or_default();
            std::fs::create_dir_all(&app_dir).ok();

            let lib_db = Arc::new(LibraryDb::open(&app_dir).unwrap_or_else(|_| {
                LibraryDb::open(&app_dir).expect("unrecoverable sled DB error")
            }));
            app.manage(lib_db);

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("SHUM failed to launch");
}
