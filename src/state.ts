import { track } from 'ripple';
import type { AudioState, TrackMeta, PlaybackState } from './types';

export function initState() {
  const _track       = track<TrackMeta | null>(null);
  const _volume      = track(0.75);
  const _progress    = track(0);
  const _duration    = track(0);
  const _playback    = track<PlaybackState>('stopped');

  const _isPlaying   = track(() => _playback.value === 'playing');
  const _progressPct = track(() =>
    _duration.value > 0 ? (_progress.value / _duration.value) * 100 : 0
  );
  const _volumePct   = track(() => Math.round(_volume.value * 100));

  function applyState(s: AudioState): void {
    if (s.currentTrack !== undefined) _track.set(s.currentTrack);
    if (s.playbackState)              _playback.set(s.playbackState);
    if (s.volume !== undefined)       _volume.set(s.volume);
    if (s.positionSecs !== undefined) _progress.set(s.positionSecs);
    if (s.currentTrack?.durationSecs) _duration.set(s.currentTrack.durationSecs);
  }

  return {
    track: _track,
    volume: _volume,
    progress: _progress,
    duration: _duration,
    playbackState: _playback,
    isPlaying: _isPlaying,
    progressPercent: _progressPct,
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
