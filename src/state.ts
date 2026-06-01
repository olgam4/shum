import { track } from 'ripple';
import type { NativeAudioState, TrackMeta } from './types';
import { actions } from './actions';
import { ctx } from './context';

const _isPlaying = track(() => ctx.playback.state.value === 'playing');
const _progressPct = track(() => {
  const p = ctx.playback;
  return p.duration.value > 0 ? (p.progress.value / p.duration.value) * 100 : 0;
});
const _volumePct = track(() => Math.round(ctx.playback.volume.value * 100));

export const computed = { isPlaying: _isPlaying, progressPct: _progressPct, volumePct: _volumePct };

export function applyAudioState(state: NativeAudioState): void {
  const p = ctx.playback;
  p.progress.value = state.currentTime;
  p.duration.value = state.duration;
  if (state.isPlaying) p.state.value = 'playing';
  else if (state.status === 'loading' || state.buffering) p.state.value = 'buffering';
  else if (state.status === 'error') p.state.value = 'error';
  else if (state.status === 'ended') {
    p.state.value = 'stopped';
    const q = ctx.queue;
    if (q.index.value + 1 < q.items.value.length) {
      const next = q.items.value[q.index.value + 1];
      actions.nextInQueue().then(() => {
        actions.getCoverArtUrl(next.coverArt).then((covUrl) => {
          actions.requestPlaySong(next, covUrl).catch(() => {});
        }).catch(() => {});
      }).catch(() => {});
    } else {
      ctx.track.current.value = null;
      actions.requestStop().catch(() => {});
    }
  } else p.state.value = 'paused';
}

actions.setOnPlayStart((meta: TrackMeta) => {
  ctx.track.current.value = meta;
  ctx.playback.state.value = 'playing';
});
actions.setOnStop(() => {
  ctx.track.current.value = null;
  ctx.playback.state.value = 'stopped';
});
actions.setOnAudioState(applyAudioState);

export function formatTime(secs: number): string {
  if (!secs || secs <= 0) return '0:00';
  const m = Math.floor(secs / 60);
  const s = Math.floor(secs % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}
