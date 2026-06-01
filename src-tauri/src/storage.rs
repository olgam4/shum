use aes_gcm::aead::{Aead, OsRng};
use aes_gcm::{AeadCore, Aes256Gcm, Key, KeyInit, Nonce};
use ring::hkdf::{KeyType, Okm, Salt, HKDF_SHA256};
use std::path::PathBuf;

use crate::navidrome::{NavidromeConfig};

const APP_SALT: &[u8] = b"shum-encryption-v1-salt-2025";

struct ShumKeyType;
impl KeyType for ShumKeyType {
    fn len(&self) -> usize { 32 }
}

fn derive_key(ikm: &[u8]) -> Key<Aes256Gcm> {
    let salt = Salt::new(HKDF_SHA256, APP_SALT);
    let prk = salt.extract(ikm);
    let okm: Okm<ShumKeyType> = prk.expand(&[], ShumKeyType).unwrap();
    let mut key_bytes = [0u8; 32];
    okm.fill(&mut key_bytes).unwrap();
    *Key::<Aes256Gcm>::from_slice(&key_bytes)
}

const KEY_MATERIAL: &[u8] = b"shum-nav-key-material-v1";

pub fn load_config(app_dir: &PathBuf) -> Option<NavidromeConfig> {
    let config_path = app_dir.join("shum_config.enc");
    let encrypted = std::fs::read(&config_path).ok()?;
    if encrypted.len() < 12 + 16 {
        return None;
    }

    let nonce = Nonce::from_slice(&encrypted[..12]);
    let ciphertext = &encrypted[12..];
    let key = derive_key(KEY_MATERIAL);

    let cipher = Aes256Gcm::new(&key);
    let plaintext = cipher.decrypt(nonce, ciphertext).ok()?;
    serde_json::from_slice(&plaintext).ok()
}

pub fn save_config(app_dir: &PathBuf, config: &NavidromeConfig) -> Result<(), String> {
    let config_path = app_dir.join("shum_config.enc");
    let key = derive_key(KEY_MATERIAL);
    let cipher = Aes256Gcm::new(&key);
    let nonce = Aes256Gcm::generate_nonce(&mut OsRng);

    let plaintext = serde_json::to_vec(config).map_err(|e| e.to_string())?;
    let ciphertext = cipher
        .encrypt(&nonce, plaintext.as_ref())
        .map_err(|e| e.to_string())?;

    let mut output = nonce.to_vec();
    output.extend_from_slice(&ciphertext);
    std::fs::write(&config_path, &output).map_err(|e| e.to_string())?;

    Ok(())
}

pub struct LibraryDb {
    db: sled::Db,
}

impl LibraryDb {
    pub fn open(app_dir: &PathBuf) -> Result<Self, String> {
        let db_path = app_dir.join("shum_library");
        let db = sled::open(&db_path).map_err(|e| e.to_string())?;
        Ok(Self { db })
    }

    pub fn clear(&self) -> Result<(), String> {
        self.db.clear().map_err(|e| e.to_string())
    }

    pub fn insert_song(&self, song: &crate::navidrome::LibrarySong) -> Result<(), String> {
        let key = format!("songs:{}", song.id);
        let val = serde_json::to_vec(song).map_err(|e| e.to_string())?;
        self.db.insert(key.as_bytes(), val).map_err(|e| e.to_string())?;
        Ok(())
    }

    pub fn insert_album(&self, album: &crate::navidrome::LibraryAlbum) -> Result<(), String> {
        let key = format!("albums:{}", album.id);
        let val = serde_json::to_vec(album).map_err(|e| e.to_string())?;
        self.db.insert(key.as_bytes(), val).map_err(|e| e.to_string())?;
        Ok(())
    }

    pub fn insert_artist(&self, artist: &crate::navidrome::LibraryArtist) -> Result<(), String> {
        let key = format!("artists:{}", artist.id);
        let val = serde_json::to_vec(artist).map_err(|e| e.to_string())?;
        self.db.insert(key.as_bytes(), val).map_err(|e| e.to_string())?;
        Ok(())
    }

    pub fn get_all_songs(&self) -> Vec<crate::navidrome::LibrarySong> {
        self.db
            .scan_prefix("songs:")
            .filter_map(|r| r.ok())
            .filter_map(|(_, v)| serde_json::from_slice::<crate::navidrome::LibrarySong>(&v).ok())
            .collect()
    }

    pub fn get_all_albums(&self) -> Vec<crate::navidrome::LibraryAlbum> {
        self.db
            .scan_prefix("albums:")
            .filter_map(|r| r.ok())
            .filter_map(|(_, v)| serde_json::from_slice::<crate::navidrome::LibraryAlbum>(&v).ok())
            .collect()
    }

    pub fn get_all_artists(&self) -> Vec<crate::navidrome::LibraryArtist> {
        self.db
            .scan_prefix("artists:")
            .filter_map(|r| r.ok())
            .filter_map(|(_, v)| serde_json::from_slice::<crate::navidrome::LibraryArtist>(&v).ok())
            .collect()
    }

    pub fn search_songs(&self, query: &str) -> Vec<crate::navidrome::LibrarySong> {
        let lower = query.to_lowercase();
        self.get_all_songs()
            .into_iter()
            .filter(|s| {
                s.title.to_lowercase().contains(&lower)
                    || s.artist.to_lowercase().contains(&lower)
                    || s.album.to_lowercase().contains(&lower)
            })
            .collect()
    }

    pub fn search_albums(&self, query: &str) -> Vec<crate::navidrome::LibraryAlbum> {
        let lower = query.to_lowercase();
        self.get_all_albums()
            .into_iter()
            .filter(|a| {
                a.name.to_lowercase().contains(&lower)
                    || a.artist.to_lowercase().contains(&lower)
            })
            .collect()
    }

    pub fn search_artists(&self, query: &str) -> Vec<crate::navidrome::LibraryArtist> {
        let lower = query.to_lowercase();
        self.get_all_artists()
            .into_iter()
            .filter(|a| a.name.to_lowercase().contains(&lower))
            .collect()
    }

    pub fn song_count(&self) -> u32 {
        self.db.scan_prefix("songs:").count() as u32
    }

    pub fn album_count(&self) -> u32 {
        self.db.scan_prefix("albums:").count() as u32
    }

    pub fn artist_count(&self) -> u32 {
        self.db.scan_prefix("artists:").count() as u32
    }

    pub fn set_last_sync(&self, timestamp: &str) -> Result<(), String> {
        self.db
            .insert(b"meta:last_sync", timestamp.as_bytes())
            .map_err(|e| e.to_string())?;
        Ok(())
    }

    pub fn get_last_sync(&self) -> Option<String> {
        self.db
            .get(b"meta:last_sync")
            .ok()
            .flatten()
            .map(|v| String::from_utf8_lossy(&v).to_string())
    }

    pub fn get_cache_dir(app_dir: &PathBuf) -> PathBuf {
        app_dir.join("shum_cache")
    }
}
