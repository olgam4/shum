use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NavidromeConfig {
    pub server_url: String,
    pub username: String,
    pub password_hex: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibrarySong {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub artist_id: String,
    pub album_id: String,
    pub duration: u32,
    pub track: u32,
    pub year: u32,
    pub content_type: String,
    pub suffix: String,
    pub cover_art: String,
    pub size: u64,
    pub bit_rate: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryAlbum {
    pub id: String,
    pub name: String,
    pub artist: String,
    pub artist_id: String,
    pub year: u32,
    pub cover_art: String,
    pub song_count: u32,
    pub duration: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryArtist {
    pub id: String,
    pub name: String,
    pub cover_art: String,
    pub album_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    pub artists: Vec<LibraryArtist>,
    pub albums: Vec<LibraryAlbum>,
    pub songs: Vec<LibrarySong>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectionStatus {
    pub connected: bool,
    pub server_name: Option<String>,
    pub server_version: Option<String>,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibrarySnapshot {
    pub artist_count: u32,
    pub album_count: u32,
    pub song_count: u32,
    pub last_sync: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheProgress {
    pub song_id: String,
    pub status: String,
    pub local_path: Option<String>,
}

#[derive(Clone)]
pub struct NavidromeClient {
    pub config: NavidromeConfig,
    http: reqwest::Client,
}

impl NavidromeClient {
    pub fn new(config: NavidromeConfig) -> Self {
        Self {
            config,
            http: reqwest::Client::new(),
        }
    }

    fn auth_params(&self) -> Vec<(&str, &str)> {
        vec![
            ("u", self.config.username.as_str()),
            ("p", self.config.password_hex.as_str()),
            ("v", "1.16.1"),
            ("c", "SHUM"),
            ("f", "json"),
        ]
    }

    pub async fn ping(&self) -> Result<(String, String), String> {
        let url = format!("{}/rest/ping", self.config.server_url);
        let resp = self
            .http
            .get(&url)
            .query(&self.auth_params())
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let body: serde_json::Value =
            resp.json().await.map_err(|e| format!("invalid response: {}", e))?;

        let status = body["subsonic-response"]["status"]
            .as_str()
            .unwrap_or("failed");
        if status != "ok" {
            let msg = body["subsonic-response"]["error"]["message"]
                .as_str()
                .unwrap_or("unknown error");
            return Err(msg.to_string());
        }

        let server_type = body["subsonic-response"]["type"]
            .as_str()
            .unwrap_or("unknown")
            .to_string();
        let server_version = body["subsonic-response"]["serverVersion"]
            .as_str()
            .unwrap_or("unknown")
            .to_string();

        Ok((server_type, server_version))
    }

    pub async fn search3(
        &self,
        query: &str,
        artist_offset: u32,
        artist_count: u32,
        album_offset: u32,
        album_count: u32,
        song_offset: u32,
        song_count: u32,
    ) -> Result<SearchResult, String> {
        let url = format!("{}/rest/search3", self.config.server_url);
        let mut params = self.auth_params();
        let aoff_str = artist_offset.to_string();
        let acnt_str = artist_count.to_string();
        let loff_str = album_offset.to_string();
        let lcnt_str = album_count.to_string();
        let soff_str = song_offset.to_string();
        let scnt_str = song_count.to_string();
        params.push(("query", query));
        params.push(("artistOffset", &aoff_str));
        params.push(("artistCount", &acnt_str));
        params.push(("albumOffset", &loff_str));
        params.push(("albumCount", &lcnt_str));
        params.push(("songOffset", &soff_str));
        params.push(("songCount", &scnt_str));

        let resp = self
            .http
            .get(&url)
            .query(&params)
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let body: serde_json::Value =
            resp.json().await.map_err(|e| format!("invalid response: {}", e))?;

        let status = body["subsonic-response"]["status"]
            .as_str()
            .unwrap_or("failed");
        if status != "ok" {
            let msg = body["subsonic-response"]["error"]["message"]
                .as_str()
                .unwrap_or("unknown error");
            return Err(msg.to_string());
        }

        let sr = &body["subsonic-response"]["searchResult3"];
        let artists = serde_json::from_value::<Vec<serde_json::Value>>(
            sr["artist"].clone(),
        )
        .unwrap_or_default()
        .iter()
        .map(|a| LibraryArtist {
            id: a["id"].as_str().unwrap_or("").to_string(),
            name: a["name"].as_str().unwrap_or("").to_string(),
            cover_art: a["coverArt"].as_str().unwrap_or("").to_string(),
            album_count: a["albumCount"].as_u64().unwrap_or(0) as u32,
        })
        .collect();

        let albums = serde_json::from_value::<Vec<serde_json::Value>>(
            sr["album"].clone(),
        )
        .unwrap_or_default()
        .iter()
        .map(|a| LibraryAlbum {
            id: a["id"].as_str().unwrap_or("").to_string(),
            name: a["name"].as_str().unwrap_or("").to_string(),
            artist: a["artist"].as_str().unwrap_or("").to_string(),
            artist_id: a["artistId"].as_str().unwrap_or("").to_string(),
            year: a["year"].as_u64().unwrap_or(0) as u32,
            cover_art: a["coverArt"].as_str().unwrap_or("").to_string(),
            song_count: a["songCount"].as_u64().unwrap_or(0) as u32,
            duration: a["duration"].as_u64().unwrap_or(0) as u32,
        })
        .collect();

        let songs = serde_json::from_value::<Vec<serde_json::Value>>(
            sr["song"].clone(),
        )
        .unwrap_or_default()
        .iter()
        .map(|s| LibrarySong {
            id: s["id"].as_str().unwrap_or("").to_string(),
            title: s["title"].as_str().unwrap_or("").to_string(),
            artist: s["artist"].as_str().unwrap_or("").to_string(),
            album: s["album"].as_str().unwrap_or("").to_string(),
            artist_id: s["artistId"].as_str().unwrap_or("").to_string(),
            album_id: s["albumId"].as_str().unwrap_or("").to_string(),
            duration: s["duration"].as_u64().unwrap_or(0) as u32,
            track: s["track"].as_u64().unwrap_or(0) as u32,
            year: s["year"].as_u64().unwrap_or(0) as u32,
            content_type: s["contentType"].as_str().unwrap_or("").to_string(),
            suffix: s["suffix"].as_str().unwrap_or("").to_string(),
            cover_art: s["coverArt"].as_str().unwrap_or("").to_string(),
            size: s["size"].as_u64().unwrap_or(0),
            bit_rate: s["bitRate"].as_u64().unwrap_or(0) as u32,
        })
        .collect();

        Ok(SearchResult {
            artists,
            albums,
            songs,
        })
    }

    pub fn stream_url(&self, id: &str) -> String {
        let params: Vec<String> = self
            .auth_params()
            .iter()
            .map(|(k, v)| format!("{}={}", k, v))
            .collect();
        format!(
            "{}/rest/stream?id={}&{}",
            self.config.server_url,
            id,
            params.join("&")
        )
    }

    pub fn cover_art_url(&self, id: &str) -> String {
        let params: Vec<String> = self
            .auth_params()
            .iter()
            .map(|(k, v)| format!("{}={}", k, v))
            .collect();
        format!(
            "{}/rest/getCoverArt?id={}&{}",
            self.config.server_url,
            id,
            params.join("&")
        )
    }

    pub async fn download_song(
        &self,
        id: &str,
        local_path: &str,
    ) -> Result<String, String> {
        let url = self.stream_url(id);
        let resp = self
            .http
            .get(&url)
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let bytes = resp.bytes().await.map_err(|e| e.to_string())?;
        std::fs::write(local_path, &bytes).map_err(|e| e.to_string())?;

        Ok(local_path.to_string())
    }
}
