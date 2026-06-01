import { invoke } from '@tauri-apps/api/core';
import type { TrackMeta, ConnectionInfo, LibrarySnapshot, SearchResult, CacheProgress } from './types';

export const actions = {
  requestPlay(track: TrackMeta | null) {
    if (track) return invoke('resume');
    return invoke('play_track', {
      id: 'default', title: 'Test Tone', artist: 'SHUM',
      album: 'System', durationSecs: 180, coverArtUrl: null,
      streamUrl: '', localPath: null,
    });
  },

  requestPlaySong(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string }, coverArtUrl: string) {
    return invoke('play_track', {
      id: song.id, title: song.title, artist: song.artist,
      album: song.album, durationSecs: song.duration,
      coverArtUrl, streamUrl: '', localPath: null,
    });
  },

  requestPlayUrl(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string }, streamUrl: string, coverArtUrl: string) {
    return invoke('play_track', {
      id: song.id, title: song.title, artist: song.artist,
      album: song.album, durationSecs: song.duration,
      coverArtUrl, streamUrl, localPath: null,
    });
  },

  requestPlayLocal(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string }, localPath: string, coverArtUrl: string) {
    return invoke('play_track', {
      id: song.id, title: song.title, artist: song.artist,
      album: song.album, durationSecs: song.duration,
      coverArtUrl, streamUrl: '', localPath,
    });
  },

  requestPause()     { return invoke('pause'); },
  requestStop()      { return invoke('stop'); },
  requestSeek(pos: number)  { return invoke('seek', { positionSecs: pos }); },
  requestSetVolume(v: number) { return invoke('set_volume', { volume: Math.max(0, Math.min(1, v)) }); },

  async connectServer(url: string, username: string, password: string): Promise<ConnectionInfo> {
    return invoke('connect_server', { serverUrl: url, username, password });
  },

  disconnect(): Promise<ConnectionInfo> {
    return invoke('disconnect');
  },

  syncLibrary(): Promise<LibrarySnapshot> {
    return invoke('sync_library');
  },

  searchLibrary(query: string): Promise<SearchResult> {
    return invoke('search_library', { query });
  },

  async getStreamUrl(id: string): Promise<string> {
    return invoke('get_stream_url', { id });
  },

  async getCoverArtUrl(id: string): Promise<string> {
    return invoke('get_cover_art_url', { id });
  },

  cacheSong(id: string): Promise<CacheProgress> {
    return invoke('cache_song', { id });
  },

  getCachedSongPath(id: string): Promise<string | null> {
    return invoke('get_cached_song_path', { id });
  },

  async haptic(type: 'light' | 'medium' | 'heavy' | 'success' | 'error' | 'selection') {
    const map: Record<string, string> = {
      light: 'impactLight', medium: 'impactMedium', heavy: 'impactHeavy',
      success: 'notificationSuccess', error: 'notificationError', selection: 'selection',
    };
    try { await invoke(`plugin:haptics|${map[type]}`); } catch { /* noop */ }
  },
};
