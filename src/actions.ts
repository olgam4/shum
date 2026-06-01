import { invoke } from '@tauri-apps/api/core';
import {
  initialize, setSource, play, pause, seekTo, dispose,
  addStateListener,
} from 'tauri-plugin-native-audio-api';
import type { TrackMeta, ConnectionInfo, AppState, SearchResult, CacheProgress, Route, NativeAudioState } from './types';

let _onPlayStart: ((meta: TrackMeta) => void) | null = null;
let _onStop: (() => void) | null = null;
let _onAudioState: ((state: NativeAudioState) => void) | null = null;
let _audioReady = false;
let _playbackSeq = Promise.resolve();
let _playbackId = 0;
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

  getState(): Promise<AppState> {
    return invoke('get_state');
  },

  navigate(route: Route): Promise<AppState> {
    return invoke('navigate', { route });
  },

  openPlayer(): Promise<AppState> {
    return invoke('set_player_open', { open: true });
  },

  closePlayer(): Promise<AppState> {
    return invoke('set_player_open', { open: false });
  },

  async requestPlaySong(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string }, coverArtUrl: string) {
    const streamUrl = await invoke<string>('get_stream_url', { id: song.id });
    return actions.requestPlayUrl(song, streamUrl, coverArtUrl);
  },

  async requestPlayUrl(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string }, streamUrl: string, coverArtUrl: string) {
    const id = ++_playbackId;
    _playbackSeq = _playbackSeq.then(async () => {
      if (id !== _playbackId) return;
      _unlistenAudio?.();
      _unlistenAudio = null;
      if (_audioReady) {
        await dispose().catch(() => {});
        _audioReady = false;
      }
      if (id !== _playbackId) return;
      await initialize();
      _audioReady = true;
      _registerStateListener();
      if (id !== _playbackId) return;
      _onPlayStart?.({
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        durationSecs: song.duration,
        coverArtUrl: coverArtUrl || null,
      });
      await setSource({
        src: streamUrl,
        title: song.title,
        artist: song.artist,
        artworkUrl: coverArtUrl || undefined,
      });
      if (id !== _playbackId) return;
      await play();
    }).then(() => {});
    return _playbackSeq;
  },

  async requestPlayLocal(song: { id: string; title: string; artist: string; album: string; duration: number; coverArt: string }, localPath: string, coverArtUrl: string) {
    const id = ++_playbackId;
    _playbackSeq = _playbackSeq.then(async () => {
      if (id !== _playbackId) return;
      _unlistenAudio?.();
      _unlistenAudio = null;
      if (_audioReady) {
        await dispose().catch(() => {});
        _audioReady = false;
      }
      if (id !== _playbackId) return;
      await initialize();
      _audioReady = true;
      _registerStateListener();
      if (id !== _playbackId) return;
      _onPlayStart?.({
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        durationSecs: song.duration,
        coverArtUrl: coverArtUrl || null,
      });
      await setSource({
        src: `file://${localPath}`,
        title: song.title,
        artist: song.artist,
        artworkUrl: coverArtUrl || undefined,
      });
      if (id !== _playbackId) return;
      await play();
    }).then(() => {});
    return _playbackSeq;
  },

  requestPlay(track: TrackMeta | null) {
    if (track) return play();
    return Promise.resolve();
  },

  requestPause()     { return pause(); },
  requestStop()      {
    ++_playbackId;
    _onStop?.();
    _unlistenAudio?.();
    _unlistenAudio = null;
    _audioReady = false;
    return dispose();
  },
  requestSeek(pos: number)  { return seekTo(pos); },
  requestSetVolume(_v: number) { /* plugin has no volume control */ },

  async connectServer(url: string, username: string, password: string): Promise<ConnectionInfo> {
    return invoke('connect_server', { serverUrl: url, username, password });
  },

  disconnect(): Promise<AppState> {
    return invoke('disconnect');
  },

  syncLibrary(): Promise<AppState> {
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
