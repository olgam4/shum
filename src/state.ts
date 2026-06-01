import { track } from 'ripple';
import type {
  AppState, TrackMeta, PlaybackState, ConnectionInfo, ConnectionStatus,
  SearchResult, Route, NativeAudioState,
} from './types';
import { actions } from './actions';

export function initState() {
  const _track        = track<TrackMeta | null>(null);
  const _volume       = track(0.75);
  const _progress     = track(0);
  const _duration     = track(0);
  const _playback     = track<PlaybackState>('stopped');
  const _connInfo     = track<ConnectionInfo>({ connected: false });
  const _connection   = track<ConnectionStatus>('disconnected');
  const _route        = track<Route>('home');
  const _playerOpen   = track(false);
  const _library      = track<SearchResult>({ artists: [], albums: [], songs: [] });
  const _lastSync     = track<string | null>(null);
  const _syncArtistCount = track(0);
  const _syncAlbumCount  = track(0);
  const _syncSongCount   = track(0);
  const _syncing         = track(false);

  const _isPlaying   = track(() => _playback.value === 'playing');
  const _progressPct = track(() =>
    _duration.value > 0 ? (_progress.value / _duration.value) * 100 : 0
  );
  const _volumePct   = track(() => Math.round(_volume.value * 100));

  function applyState(s: AppState): void {
    if (s.connectionStatus !== undefined) {
      _connInfo.value = s.connectionStatus;
      _connection.value = s.connectionStatus.connected ? 'connected' : 'disconnected';
    }
    if (s.library !== undefined) _library.value = s.library;
    if (s.libraryArtistCount !== undefined) _syncArtistCount.value = s.libraryArtistCount;
    if (s.libraryAlbumCount !== undefined) _syncAlbumCount.value = s.libraryAlbumCount;
    if (s.librarySongCount !== undefined) _syncSongCount.value = s.librarySongCount;
    if (s.libraryLastSync !== undefined) _lastSync.value = s.libraryLastSync;
    if (s.syncing !== undefined) _syncing.value = s.syncing;
    if (s.route !== undefined) _route.value = s.route;
    if (s.playerOpen !== undefined) _playerOpen.value = s.playerOpen;
  }

  function applyAudioState(state: NativeAudioState): void {
    _progress.value = state.currentTime;
    _duration.value = state.duration;
    if (state.isPlaying) _playback.value = 'playing';
    else if (state.status === 'loading' || state.buffering) _playback.value = 'buffering';
    else if (state.status === 'ended') _playback.value = 'stopped';
    else _playback.value = 'paused';
  }

  actions.setOnPlayStart((meta: TrackMeta) => {
    _track.value = meta;
  });
  actions.setOnStop(() => {
    _track.value = null;
    _playback.value = 'stopped';
  });
  actions.setOnAudioState(applyAudioState);

  return {
    track: _track, volume: _volume, progress: _progress,
    duration: _duration, playbackState: _playback,
    connection: _connection, connectionInfo: _connInfo,
    route: _route, playerOpen: _playerOpen,
    library: _library, lastSync: _lastSync,
    syncArtistCount: _syncArtistCount, syncAlbumCount: _syncAlbumCount,
    syncSongCount: _syncSongCount,
    syncing: _syncing,
    isPlaying: _isPlaying, progressPercent: _progressPct,
    volumePercent: _volumePct,
    applyState,
  };
}

export function formatTime(secs: number): string {
  if (!secs || secs <= 0) return '0:00';
  const m = Math.floor(secs / 60);
  const s = Math.floor(secs % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}
