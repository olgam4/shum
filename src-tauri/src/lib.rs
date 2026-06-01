mod audio;
mod navidrome;
mod storage;

use audio::{AudioManager, AudioState, TrackMeta};
use navidrome::{
    CacheProgress, ConnectionStatus, LibrarySnapshot, NavidromeClient, NavidromeConfig,
    SearchResult,
};
use std::sync::{Arc, Mutex};
use std::time::Duration;
use storage::{load_config, save_config, LibraryDb};
use tauri::{AppHandle, Emitter, Manager, State};

type AudioManagerType = AudioManager<NativeAudio>;

pub struct NativeAudio {
    playback_position: f64,
}

impl NativeAudio {
    pub fn new() -> Self {
        Self {
            playback_position: 0.0,
        }
    }
}

impl audio::AudioPlatform for NativeAudio {
    fn load_url(&mut self, _url: &str) -> Result<(), String> {
        log::info!("[NativeAudio] load_url: {}", _url);
        self.playback_position = 0.0;
        Ok(())
    }

    fn load_file(&mut self, path: &str) -> Result<(), String> {
        log::info!("[NativeAudio] load_file: {}", path);
        self.playback_position = 0.0;
        Ok(())
    }

    fn play(&mut self) -> Result<(), String> {
        log::info!("[NativeAudio] play");
        Ok(())
    }

    fn pause(&mut self) -> Result<(), String> {
        log::info!("[NativeAudio] pause");
        Ok(())
    }

    fn stop(&mut self) -> Result<(), String> {
        log::info!("[NativeAudio] stop");
        self.playback_position = 0.0;
        Ok(())
    }

    fn seek(&mut self, position_secs: f64) -> Result<(), String> {
        log::info!("[NativeAudio] seek to {:.2}s", position_secs);
        self.playback_position = position_secs;
        Ok(())
    }

    fn set_volume(&mut self, volume: f64) -> Result<(), String> {
        log::info!("[NativeAudio] set volume: {:.2}", volume);
        Ok(())
    }

    fn current_position(&self) -> f64 {
        self.playback_position
    }
}

struct NavidromeState {
    client: Option<NavidromeClient>,
}

// ─── Audio Commands ───

#[tauri::command]
fn play_track(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
    id: String,
    title: String,
    artist: String,
    album: String,
    duration_secs: f64,
    cover_art_url: Option<String>,
    stream_url: String,
    local_path: Option<String>,
) -> Result<AudioState, String> {
    log::info!("[play_track] {} - {}", artist, title);

    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let track = TrackMeta {
        id,
        title,
        artist,
        album,
        duration_secs,
        cover_art_url,
    };

    let result = AudioManagerType::play_track(
        &manager.state(),
        &manager.platform(),
        track,
        stream_url,
        local_path,
    )?;

    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn pause(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
) -> Result<AudioState, String> {
    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let result = AudioManagerType::pause(&manager.state(), &manager.platform())?;
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn resume(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
) -> Result<AudioState, String> {
    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let result = AudioManagerType::resume(&manager.state(), &manager.platform())?;
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn stop(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
) -> Result<AudioState, String> {
    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let result = AudioManagerType::stop(&manager.state(), &manager.platform())?;
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn seek(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
    position_secs: f64,
) -> Result<AudioState, String> {
    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let result =
        AudioManagerType::seek(&manager.state(), &manager.platform(), position_secs)?;
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn set_volume(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
    volume: f64,
) -> Result<AudioState, String> {
    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let result =
        AudioManagerType::set_volume(&manager.state(), &manager.platform(), volume)?;
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn get_state(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
) -> Result<AudioState, String> {
    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let binding = manager.state();
    let s = binding.lock().map_err(|e| e.to_string())?;
    Ok(s.clone())
}

// ─── Navidrome Commands ───

#[tauri::command]
async fn connect_server(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    app_handle: AppHandle,
    server_url: String,
    username: String,
    password: String,
) -> Result<ConnectionStatus, String> {
    let password_hex = hex::encode(password.as_bytes());

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
            let _ = app_handle.emit("shum:connection-changed", &status);
            Ok(status)
        }
        Err(e) => {
            let status = ConnectionStatus {
                connected: false,
                server_name: None,
                server_version: None,
                error: Some(e),
            };
            let _ = app_handle.emit("shum:connection-changed", &status);
            Ok(status)
        }
    }
}

#[tauri::command]
fn disconnect(
    nav_state: State<'_, Arc<Mutex<NavidromeState>>>,
    app_handle: AppHandle,
) -> Result<ConnectionStatus, String> {
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
    let _ = app_handle.emit("shum:connection-changed", &status);
    Ok(status)
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
    app_handle: AppHandle,
) -> Result<LibrarySnapshot, String> {
    let client = {
        let ns = nav_state.inner().lock().map_err(|e| e.to_string())?;
        ns.client.clone().ok_or("not connected")?
    };

    lib_db.clear()?;

    let mut all_songs = Vec::new();
    let mut all_albums = Vec::new();
    let mut all_artists = Vec::new();

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

        all_songs.extend(results.songs);
        all_albums.extend(results.albums);
        all_artists.extend(results.artists);

        song_offset += batch_size;
        album_offset += batch_size;
        artist_offset += batch_size;
    }

    let now = chrono_now();
    lib_db.set_last_sync(&now)?;

    let snapshot = LibrarySnapshot {
        artist_count: lib_db.artist_count(),
        album_count: lib_db.album_count(),
        song_count: lib_db.song_count(),
        last_sync: now,
    };

    let _ = app_handle.emit("shum:library-synced", &snapshot);
    Ok(snapshot)
}

#[tauri::command]
async fn search_library(
    lib_db: State<'_, Arc<LibraryDb>>,
    query: String,
) -> Result<SearchResult, String> {
    if query.is_empty() {
        return Ok(SearchResult {
            artists: lib_db.get_all_artists(),
            albums: lib_db.get_all_albums(),
            songs: lib_db.get_all_songs(),
        });
    }

    Ok(SearchResult {
        artists: lib_db.search_artists(&query),
        albums: lib_db.search_albums(&query),
        songs: lib_db.search_songs(&query),
    })
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

// ─── Helpers ───

fn chrono_now() -> String {
    use std::time::SystemTime;
    let ts = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    format!("{}", ts)
}

// ─── Entry Point ───

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    env_logger::init();

    let audio_manager = Arc::new(Mutex::new(AudioManager::new(NativeAudio::new())));
    let nav_state = Arc::new(Mutex::new(NavidromeState { client: None }));

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_haptics::init())
        .manage(audio_manager)
        .manage(nav_state)
        .invoke_handler(tauri::generate_handler![
            play_track,
            pause,
            resume,
            stop,
            seek,
            set_volume,
            get_state,
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
        .setup(|app| {
            log::info!("[SHUM] Tauri v2 mobile backend initialised");

            let app_dir = app.path().app_data_dir().map_err(|e| e.to_string()).unwrap_or_default();
            std::fs::create_dir_all(&app_dir).ok();

            // Restore saved connection
            if let Some(config) = load_config(&app_dir) {
                let client = NavidromeClient::new(config);
                let handle = app.handle().clone();
                let ns_clone = app.state::<Arc<Mutex<NavidromeState>>>().inner().clone();

                tauri::async_runtime::spawn(async move {
                    match client.ping().await {
                        Ok((server_type, server_version)) => {
                            let mut ns = ns_clone.lock().unwrap();
                            ns.client = Some(client);
                            drop(ns);

                            let status = ConnectionStatus {
                                connected: true,
                                server_name: Some(server_type),
                                server_version: Some(server_version),
                                error: None,
                            };
                            let _ = handle.emit("shum:connection-changed", &status);
                        }
                        Err(e) => {
                            log::warn!("[SHUM] auto-connect failed: {}", e);
                            let status = ConnectionStatus {
                                connected: false,
                                server_name: None,
                                server_version: None,
                                error: Some(e),
                            };
                            let _ = handle.emit("shum:connection-changed", &status);
                        }
                    }
                });
            }

            // Open library DB
            let lib_db = Arc::new(LibraryDb::open(&app_dir).unwrap_or_else(|_| {
                LibraryDb::open(&app_dir).expect("unrecoverable sled DB error")
            }));
            app.manage(lib_db.clone());

            let handle = app.handle().clone();
            let audio_arc = app.state::<Arc<Mutex<AudioManagerType>>>().inner().clone();

            std::thread::spawn(move || {
                let position_interval = Duration::from_millis(500);
                loop {
                    std::thread::sleep(position_interval);
                    let manager = match audio_arc.lock() {
                        Ok(m) => m,
                        Err(_) => break,
                    };
                    let result = AudioManagerType::tick_position(
                        &manager.state(),
                        &manager.platform(),
                    );
                    match result {
                        Ok(audio_state) => {
                            let _ = handle.emit("shum:position-tick", &audio_state);
                        }
                        Err(e) => {
                            log::error!("[SHUM] position tick error: {}", e);
                        }
                    }
                }
            });

            // Emit library snapshot on startup
            if lib_db.song_count() > 0 {
                let snapshot = LibrarySnapshot {
                    artist_count: lib_db.artist_count(),
                    album_count: lib_db.album_count(),
                    song_count: lib_db.song_count(),
                    last_sync: lib_db.get_last_sync().unwrap_or_default(),
                };
                let h = app.handle().clone();
                std::thread::spawn(move || {
                    std::thread::sleep(Duration::from_millis(300));
                    let _ = h.emit("shum:library-synced", &snapshot);
                });
            }

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("SHUM failed to launch");
}
