use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum PlaybackState {
    Playing,
    Paused,
    Stopped,
    Buffering,
}

impl PlaybackState {
    #[allow(dead_code)]
    pub fn as_str(&self) -> &'static str {
        match self {
            PlaybackState::Playing => "playing",
            PlaybackState::Paused => "paused",
            PlaybackState::Stopped => "stopped",
            PlaybackState::Buffering => "buffering",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrackMeta {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_secs: f64,
    pub cover_art_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AudioState {
    pub current_track: Option<TrackMeta>,
    pub playback_state: PlaybackState,
    pub volume: f64,
    pub position_secs: f64,
}

impl Default for AudioState {
    fn default() -> Self {
        Self {
            current_track: None,
            playback_state: PlaybackState::Stopped,
            volume: 0.75,
            position_secs: 0.0,
        }
    }
}

pub trait AudioPlatform {
    fn load_url(&mut self, url: &str) -> Result<(), String>;
    fn load_file(&mut self, path: &str) -> Result<(), String>;
    fn play(&mut self) -> Result<(), String>;
    fn pause(&mut self) -> Result<(), String>;
    fn stop(&mut self) -> Result<(), String>;
    fn seek(&mut self, position_secs: f64) -> Result<(), String>;
    fn set_volume(&mut self, volume: f64) -> Result<(), String>;
    fn current_position(&self) -> f64;
}

pub struct AudioManager<P: AudioPlatform> {
    state: Arc<Mutex<AudioState>>,
    platform: Arc<Mutex<P>>,
}

impl<P: AudioPlatform> AudioManager<P> {
    pub fn new(platform: P) -> Self {
        Self {
            state: Arc::new(Mutex::new(AudioState::default())),
            platform: Arc::new(Mutex::new(platform)),
        }
    }

    pub fn state(&self) -> Arc<Mutex<AudioState>> {
        Arc::clone(&self.state)
    }

    pub fn platform(&self) -> Arc<Mutex<P>> {
        Arc::clone(&self.platform)
    }

    pub fn play_track(
        state: &Arc<Mutex<AudioState>>,
        platform: &Arc<Mutex<P>>,
        track: TrackMeta,
        stream_url: String,
        local_path: Option<String>,
    ) -> Result<AudioState, String> {
        let mut plat = platform.lock().map_err(|e| e.to_string())?;

        if let Some(ref path) = local_path {
            plat.load_file(path)?;
        } else {
            plat.load_url(&stream_url)?;
        }

        let mut s = state.lock().map_err(|e| e.to_string())?;
        s.current_track = Some(track);
        s.position_secs = 0.0;

        plat.play()?;
        s.playback_state = PlaybackState::Playing;

        Ok(s.clone())
    }

    pub fn pause(
        state: &Arc<Mutex<AudioState>>,
        platform: &Arc<Mutex<P>>,
    ) -> Result<AudioState, String> {
        let mut plat = platform.lock().map_err(|e| e.to_string())?;
        plat.pause()?;

        let mut s = state.lock().map_err(|e| e.to_string())?;
        s.playback_state = PlaybackState::Paused;

        Ok(s.clone())
    }

    pub fn resume(
        state: &Arc<Mutex<AudioState>>,
        platform: &Arc<Mutex<P>>,
    ) -> Result<AudioState, String> {
        let mut plat = platform.lock().map_err(|e| e.to_string())?;
        plat.play()?;

        let mut s = state.lock().map_err(|e| e.to_string())?;
        s.playback_state = PlaybackState::Playing;

        Ok(s.clone())
    }

    pub fn stop(
        state: &Arc<Mutex<AudioState>>,
        platform: &Arc<Mutex<P>>,
    ) -> Result<AudioState, String> {
        let mut plat = platform.lock().map_err(|e| e.to_string())?;
        plat.stop()?;

        let mut s = state.lock().map_err(|e| e.to_string())?;
        s.playback_state = PlaybackState::Stopped;
        s.current_track = None;
        s.position_secs = 0.0;

        Ok(s.clone())
    }

    pub fn seek(
        state: &Arc<Mutex<AudioState>>,
        platform: &Arc<Mutex<P>>,
        position_secs: f64,
    ) -> Result<AudioState, String> {
        let mut plat = platform.lock().map_err(|e| e.to_string())?;
        plat.seek(position_secs)?;

        let mut s = state.lock().map_err(|e| e.to_string())?;
        s.position_secs = position_secs;

        Ok(s.clone())
    }

    pub fn set_volume(
        state: &Arc<Mutex<AudioState>>,
        platform: &Arc<Mutex<P>>,
        volume: f64,
    ) -> Result<AudioState, String> {
        let clamped = volume.clamp(0.0, 1.0);
        let mut plat = platform.lock().map_err(|e| e.to_string())?;
        plat.set_volume(clamped)?;

        let mut s = state.lock().map_err(|e| e.to_string())?;
        s.volume = clamped;

        Ok(s.clone())
    }

    pub fn tick_position(
        state: &Arc<Mutex<AudioState>>,
        platform: &Arc<Mutex<P>>,
    ) -> Result<AudioState, String> {
        let plat = platform.lock().map_err(|e| e.to_string())?;
        let pos = plat.current_position();

        let mut s = state.lock().map_err(|e| e.to_string())?;
        if s.playback_state == PlaybackState::Playing {
            s.position_secs = pos;
        }

        Ok(s.clone())
    }

    #[allow(dead_code)]
    pub fn set_buffering(
        state: &Arc<Mutex<AudioState>>,
    ) -> Result<AudioState, String> {
        let mut s = state.lock().map_err(|e| e.to_string())?;
        s.playback_state = PlaybackState::Buffering;
        Ok(s.clone())
    }
}
