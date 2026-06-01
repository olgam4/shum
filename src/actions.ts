import { invoke } from '@tauri-apps/api/core';
import {
  initialize, setSource, play, pause, seekTo, dispose,
  addStateListener,
} from 'tauri-plugin-native-audio-api';
import type { TrackMeta, ConnectionInfo, SearchResult, CacheProgress, NativeAudioState, StartupState } from './types';
import { ctx } from './context';

let _onPlayStart: ((meta: TrackMeta) => void) | null = null;
let _onStop: (() => void) | null = null;
let _onAudioState: ((state: NativeAudioState) => void) | null = null;
let _audioReady = false;
let _unlistenAudio: (() => void) | null = null;

function _registerStateListener() {
  addStateListener((state: NativeAudioState) => {
    _onAudioState?.(state);
  }).then((fn) => _unlistenAudio = fn);
}

export const actions = {
  setOnPlayStart(fn: (meta: TrackMeta) => void) { _onPlayStart = fn; },
  setOnStop(fn: () => void) { _onStop = fn; },
  setOnAudioState(fn: (state: NativeAudioState) => void) { _onAudioState = fn; },

  async initAudio() {
    if (_audioReady) return;
    await initialize();
    _audioReady = true;
    _registerStateListener();
  },

  async requestPlaySong(song: { id: string; title: string; artist: string; artistId: string; album: string; albumId: string; duration: number; coverArt: string; contentType: string; suffix: string }, coverArtUrl: string) {
    const streamUrl = await invoke<string>('get_stream_url', { id: song.id });
    return actions.requestPlayUrl(song, streamUrl, coverArtUrl);
  },

  async requestPlayUrl(song: { id: string; title: string; artist: string; artistId: string; album: string; albumId: string; duration: number; coverArt: string; contentType: string; suffix: string }, streamUrl: string, coverArtUrl: string) {
    if (!_audioReady) {
      await initialize();
      _audioReady = true;
      _registerStateListener();
    }
    _onPlayStart?.({
      id: song.id,
      title: song.title,
      artist: song.artist,
      artistId: song.artistId,
      album: song.album,
      albumId: song.albumId,
      durationSecs: song.duration,
      coverArtUrl: coverArtUrl || null,
      contentType: song.contentType,
      suffix: song.suffix,
    });
    await setSource({
      src: streamUrl,
      title: song.title,
      artist: song.artist,
      artworkUrl: coverArtUrl || undefined,
    });
    return play();
  },

  async requestPlayLocal(song: { id: string; title: string; artist: string; artistId: string; album: string; albumId: string; duration: number; coverArt: string; contentType: string; suffix: string }, localPath: string, coverArtUrl: string) {
    if (!_audioReady) {
      await initialize();
      _audioReady = true;
      _registerStateListener();
    }
    _onPlayStart?.({
      id: song.id,
      title: song.title,
      artist: song.artist,
      artistId: song.artistId,
      album: song.album,
      albumId: song.albumId,
      durationSecs: song.duration,
      coverArtUrl: coverArtUrl || null,
      contentType: song.contentType,
      suffix: song.suffix,
    });
    await setSource({
      src: `file://${localPath}`,
      title: song.title,
      artist: song.artist,
      artworkUrl: coverArtUrl || undefined,
    });
    return play();
  },

  requestPlay(track: TrackMeta | null) {
    if (track) return play();
    return Promise.resolve();
  },

  requestPause()     { return pause(); },
  requestStop()      {
    _onStop?.();
    _unlistenAudio?.();
    _unlistenAudio = null;
    _audioReady = false;
    return dispose();
  },
  requestSeek(pos: number)  { return seekTo(pos); },

  async connectServer(url: string, username: string, password: string): Promise<ConnectionInfo> {
    return invoke('connect_server', { serverUrl: url, username, password });
  },

  disconnect(): Promise<void> {
    return invoke('disconnect');
  },

  syncLibrary(): Promise<import('./types').SyncResult> {
    return invoke('sync_library');
  },

  startupHydrate(): Promise<StartupState> {
    return invoke('startup_hydrate');
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

  setQueue(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string; contentType: string; suffix: string; artistId: string; albumId: string; track: number; year: number; size: number; bitRate: number }) {
    const q = ctx.queue;
    q.items.value = [song as import('./types').LibrarySong];
    q.index.value = 0;
  },

  addToQueue(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string; contentType: string; suffix: string; artistId: string; albumId: string; track: number; year: number; size: number; bitRate: number }) {
    const q = ctx.queue;
    q.items.value = [...q.items.value, song as import('./types').LibrarySong];
  },

  nextInQueue() {
    const q = ctx.queue;
    q.index.value += 1;
    if (q.index.value >= q.items.value.length) {
      q.index.value = 0;
      q.items.value = [];
    }
    return Promise.resolve();
  },

  async haptic(type: 'light' | 'medium' | 'heavy' | 'success' | 'error' | 'selection') {
    const map: Record<string, string> = {
      light: 'impactLight', medium: 'impactMedium', heavy: 'impactHeavy',
      success: 'notificationSuccess', error: 'notificationError', selection: 'selection',
    };
    try { await invoke(`plugin:haptics|${map[type]}`); } catch { /* noop */ }
  },
};
