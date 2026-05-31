mod audio;

use audio::{AudioManager, AudioState, TrackMeta};
use std::sync::{Arc, Mutex};
use std::time::Duration;
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
    fn load(&mut self, _url: &str) -> Result<(), String> {
        log::info!("[NativeAudio] load track: {}", _url);
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
    )?;

    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn pause(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
) -> Result<AudioState, String> {
    log::info!("[pause]");

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
    log::info!("[resume]");

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
    log::info!("[stop]");

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
    log::info!("[seek] {:.2}s", position_secs);

    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let result = AudioManagerType::seek(&manager.state(), &manager.platform(), position_secs)?;

    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}

#[tauri::command]
fn set_volume(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
    volume: f64,
) -> Result<AudioState, String> {
    log::info!("[set_volume] {:.2}", volume);

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
    let s = manager.state().lock().map_err(|e| e.to_string())?;
    Ok(s.clone())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    env_logger::init();

    let audio_manager = AudioManager::new(NativeAudio::new());
    let managed = Arc::new(Mutex::new(audio_manager));

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(managed)
        .invoke_handler(tauri::generate_handler![
            play_track,
            pause,
            resume,
            stop,
            seek,
            set_volume,
            get_state,
        ])
        .setup(|app| {
            log::info!("[SHUM] Tauri v2 mobile backend initialised");

            let handle = app.handle().clone();
            let state = app.state::<Arc<Mutex<AudioManagerType>>>();

            std::thread::spawn(move || {
                let position_interval = Duration::from_millis(500);
                loop {
                    std::thread::sleep(position_interval);

                    let manager = match state.lock() {
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

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("SHUM failed to launch");
}
