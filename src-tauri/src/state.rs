use crate::navidrome::{ConnectionStatus, SearchResult};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Route {
    Home,
    Library,
    Settings,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AppState {
    pub connection_status: ConnectionStatus,

    pub library: SearchResult,
    pub library_artist_count: u32,
    pub library_album_count: u32,
    pub library_song_count: u32,
    pub library_last_sync: Option<String>,
    pub syncing: bool,

    pub route: Route,
    pub player_open: bool,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            connection_status: ConnectionStatus {
                connected: false,
                server_name: None,
                server_version: None,
                error: None,
            },
            library: SearchResult {
                artists: vec![],
                albums: vec![],
                songs: vec![],
            },
            library_artist_count: 0,
            library_album_count: 0,
            library_song_count: 0,
            library_last_sync: None,
            syncing: false,
            route: Route::Home,
            player_open: false,
        }
    }
}
