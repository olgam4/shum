mod navidrome;
mod state;
mod storage;

use navidrome::{
    CacheProgress, ConnectionStatus, NavidromeClient, NavidromeConfig,
    SearchResult,
};
use state::{AppState, Route};
use std::sync::{Arc, Mutex};
use storage::{load_config, save_config, LibraryDb};
use tauri::{AppHandle, Emitter, Manager, State};

type AppStateType = Arc<Mutex<AppState>>;

fn chrono_now() -> String {
    use std::time::SystemTime;
    let ts = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    format!("{}", ts)
}

// ─── UI Commands ───

#[tauri::command]
fn get_state(
    app_state: State<'_, AppStateType>,
) -> Result<AppState, String> {
    let s = app_state.inner().lock().map_err(|e| e.to_string())?;
    Ok(s.clone())
}

#[tauri::command]
fn navigate(
    app_state: State<'_, AppStateType>,
    app_handle: AppHandle,
    route: Route,
) -> Result<AppState, String> {
    let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
    s.route = route;
    let result = s.clone();
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn set_player_open(
    app_state: State<'_, AppStateType>,
    app_handle: AppHandle,
    open: bool,
) -> Result<AppState, String> {
    let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
    s.player_open = open;
    let result = s.clone();
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

// ─── Navidrome Commands ───

struct NavidromeState {
    client: Option<NavidromeClient>,
}

#[tauri::command]
async fn connect_server(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    app_state: State<'_, AppStateType>,
    app_handle: AppHandle,
    server_url: String,
    username: String,
    password: String,
) -> Result<AppState, String> {
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

            let status = ConnectionStatus {
                connected: true,
                server_name: Some(server_type),
                server_version: Some(server_version),
                error: None,
            };

            let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
            s.connection_status = status;
            let result = s.clone();
            let _ = app_handle.emit("shum:state-changed", &result);
            Ok(result)
        }
        Err(e) => {
            let status = ConnectionStatus {
                connected: false,
                server_name: None,
                server_version: None,
                error: Some(e),
            };

            let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
            s.connection_status = status;
            let result = s.clone();
            let _ = app_handle.emit("shum:state-changed", &result);
            Ok(result)
        }
    }
}

#[tauri::command]
fn disconnect(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    app_state: State<'_, AppStateType>,
    app_handle: AppHandle,
) -> Result<AppState, String> {
    let mut ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
    ns.client = None;

    let app_dir = app_handle.path().app_data_dir().map_err(|e| e.to_string())?;
    if let Err(e) = std::fs::remove_file(app_dir.join("shum_config.enc")) {
        log::warn!("[disconnect] could not remove config file: {}", e);
    }

    let status = ConnectionStatus {
        connected: false,
        server_name: None,
        server_version: None,
        error: None,
    };

    let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
    s.connection_status = status;
    s.library = SearchResult {
        artists: vec![],
        albums: vec![],
        songs: vec![],
    };
    s.library_artist_count = 0;
    s.library_album_count = 0;
    s.library_song_count = 0;
    s.library_last_sync = None;
    let result = s.clone();
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn get_connection_status(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
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
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    lib_db: State<'_, Arc<LibraryDb>>,
    app_state: State<'_, AppStateType>,
    app_handle: AppHandle,
) -> Result<AppState, String> {
    {
        let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
        s.syncing = true;
        let result = s.clone();
        let _ = app_handle.emit("shum:state-changed", &result);
    }

    let sync_result = async {
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
        Ok(now)
    }.await;

    match sync_result {
        Ok(now) => {
            let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
            s.library = SearchResult {
                artists: lib_db.get_all_artists(),
                albums: lib_db.get_all_albums(),
                songs: lib_db.get_all_songs(),
            };
            s.library_artist_count = lib_db.artist_count();
            s.library_album_count = lib_db.album_count();
            s.library_song_count = lib_db.song_count();
            s.library_last_sync = Some(now);
            s.syncing = false;
            let result = s.clone();
            let _ = app_handle.emit("shum:state-changed", &result);
            Ok(result)
        }
        Err(e) => {
            if let Ok(mut s) = app_state.inner().lock() {
                s.syncing = false;
                let result = s.clone();
                let _ = app_handle.emit("shum:state-changed", &result);
            }
            Err(e)
        }
    }
}

#[tauri::command]
async fn search_library(
    lib_db: State<'_, Arc<LibraryDb>>,
    app_state: State<'_, AppStateType>,
    app_handle: AppHandle,
    query: String,
) -> Result<AppState, String> {
    let results = if query.is_empty() {
        SearchResult {
            artists: lib_db.get_all_artists(),
            albums: lib_db.get_all_albums(),
            songs: lib_db.get_all_songs(),
        }
    } else {
        SearchResult {
            artists: lib_db.search_artists(&query),
            albums: lib_db.search_albums(&query),
            songs: lib_db.search_songs(&query),
        }
    };

    let mut s = app_state.inner().lock().map_err(|e| e.to_string())?;
    s.library = results;
    let result = s.clone();
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn get_stream_url(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    id: String,
) -> Result<String, String> {
    let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
    let client = ns.client.as_ref().ok_or("not connected")?;
    Ok(client.stream_url(&id))
}

#[tauri::command]
fn get_cover_art_url(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    id: String,
) -> Result<String, String> {
    let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
    let client = ns.client.as_ref().ok_or("not connected")?;
    Ok(client.cover_art_url(&id))
}

#[tauri::command]
async fn cache_song(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    app_handle: AppHandle,
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
    app_handle: AppHandle,
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

// ─── Entry Point ───

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    log::info!("[SHUM] starting Tauri v2 mobile backend");

    let nav_state = Arc::new(Mutex::new(NavidromeState { client: None }));
    let app_state: AppStateType = Arc::new(Mutex::new(AppState::default()));

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_haptics::init())
        .plugin(tauri_plugin_native_audio::init())
        .manage(nav_state)
        .manage(app_state.clone())
        .invoke_handler(tauri::generate_handler![
            get_state,
            navigate,
            set_player_open,
            connect_server,
            disconnect,
            get_connection_status,
            sync_library,
            search_library,
            get_stream_url,
            get_cover_art_url,
            cache_song,
            get_cached_song_path,
        ])
        .setup(move |app| {
            log::info!("[SHUM] Tauri v2 mobile backend initialised");

            let app_dir = app.path().app_data_dir().map_err(|e| e.to_string()).unwrap_or_default();
            std::fs::create_dir_all(&app_dir).ok();

            let config_exists = load_config(&app_dir).is_some();
            log::info!("[SHUM] config file present: {}", config_exists);
            if let Some(config) = load_config(&app_dir) {
                log::info!("[SHUM] auto-connecting to {}", config.server_url);
                let client = NavidromeClient::new(config);
                let handle = app.handle().clone();
                let ns_clone = app.state::<Arc<Mutex<NavidromeState>>>().inner().clone();
                let as_clone = app_state.clone();

                tauri::async_runtime::spawn(async move {
                    match client.ping().await {
                        Ok((server_type, server_version)) => {
                            log::info!("[SHUM] auto-connect success: {} {}", server_type, server_version);
                            let mut ns = ns_clone.lock().unwrap();
                            ns.client = Some(client);
                            drop(ns);

                            let status = ConnectionStatus {
                                connected: true,
                                server_name: Some(server_type),
                                server_version: Some(server_version),
                                error: None,
                            };

                            if let Ok(mut s) = as_clone.lock() {
                                s.connection_status = status;
                                let result = s.clone();
                                drop(s);
                                let _ = handle.emit("shum:state-changed", &result);
                            }
                        }
                        Err(e) => {
                            log::warn!("[SHUM] auto-connect failed: {}", e);
                            let status = ConnectionStatus {
                                connected: false,
                                server_name: None,
                                server_version: None,
                                error: Some(e),
                            };

                            if let Ok(mut s) = as_clone.lock() {
                                s.connection_status = status;
                                let result = s.clone();
                                drop(s);
                                let _ = handle.emit("shum:state-changed", &result);
                            }
                        }
                    }
                });
            } else {
                log::info!("[SHUM] no saved config, skipping auto-connect");
            }

            let lib_db = Arc::new(LibraryDb::open(&app_dir).unwrap_or_else(|_| {
                LibraryDb::open(&app_dir).expect("unrecoverable sled DB error")
            }));
            app.manage(lib_db.clone());

            let handle_setup = app.handle().clone();

            if lib_db.song_count() > 0 {
                if let Ok(mut s) = app_state.lock() {
                    s.library = SearchResult {
                        artists: lib_db.get_all_artists(),
                        albums: lib_db.get_all_albums(),
                        songs: lib_db.get_all_songs(),
                    };
                    s.library_artist_count = lib_db.artist_count();
                    s.library_album_count = lib_db.album_count();
                    s.library_song_count = lib_db.song_count();
                    s.library_last_sync = lib_db.get_last_sync();
                    let result = s.clone();
                    drop(s);
                    let _ = handle_setup.emit("shum:state-changed", &result);
                }
            }

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("SHUM failed to launch");
}
