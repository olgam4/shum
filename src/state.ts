import { track } from 'ripple';
import type {
  AudioState, TrackMeta, PlaybackState, ConnectionStatus,
  SearchResult, LibrarySnapshot, Route,
} from './types';

export function initState() {
  const _track       = track<TrackMeta | null>(null);
  const _volume      = track(0.75);
  const _progress    = track(0);
  const _duration    = track(0);
  const _playback    = track<PlaybackState>('stopped');
  const _connection  = track<ConnectionStatus>('disconnected');
  const _route       = track<Route>('home');
  const _playerOpen  = track(false);
  const _library     = track<SearchResult>({ artists: [], albums: [], songs: [] });
  const _lastSync    = track<string | null>(null);
  const _syncArtistCount = track(0);
  const _syncAlbumCount  = track(0);
  const _syncSongCount   = track(0);
  const _syncing         = track(false);

  const _isPlaying   = track(() => _playback.value === 'playing');
  const _progressPct = track(() =>
    _duration.value > 0 ? (_progress.value / _duration.value) * 100 : 0
  );
  const _volumePct   = track(() => Math.round(_volume.value * 100));

  function applyAudioState(s: AudioState): void {
    if (s.currentTrack !== undefined) _track.value = s.currentTrack;
    if (s.playbackState)              _playback.value = s.playbackState;
    if (s.volume !== undefined)       _volume.value = s.volume;
    if (s.positionSecs !== undefined) _progress.value = s.positionSecs;
    if (s.currentTrack?.durationSecs) _duration.value = s.currentTrack.durationSecs;
  }

  function applyConnection(info: { connected: boolean; serverName?: string; serverVersion?: string; error?: string }): void {
    if (info.connected) _connection.value = 'connected';
    else if (info.error) _connection.value = 'disconnected';
    else _connection.value = 'disconnected';
  }

  function applyLibrarySnapshot(snapshot: LibrarySnapshot): void {
    _syncArtistCount.value = snapshot.artistCount;
    _syncAlbumCount.value = snapshot.albumCount;
    _syncSongCount.value = snapshot.songCount;
    _lastSync.value = snapshot.lastSync;
  }

  function applySearchResults(results: SearchResult): void {
    _library.value = results;
  }

  return {
    track: _track, volume: _volume, progress: _progress,
    duration: _duration, playbackState: _playback,
    connection: _connection, route: _route, playerOpen: _playerOpen,
    library: _library, lastSync: _lastSync,
    syncArtistCount: _syncArtistCount, syncAlbumCount: _syncAlbumCount,
    syncSongCount: _syncSongCount,
    syncing: _syncing,
    isPlaying: _isPlaying, progressPercent: _progressPct,
    volumePercent: _volumePct,
    applyAudioState, applyConnection, applyLibrarySnapshot, applySearchResults,
  };
}

export function formatTime(secs: number): string {
  if (!secs || secs <= 0) return '0:00';
  const m = Math.floor(secs / 60);
  const s = Math.floor(secs % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}
