import { effect } from 'ripple';
import { trackCtx, playbackCtx } from './context';
import { actions } from './actions';

export function setupMediaSession() {
  effect(() => {
    const meta = trackCtx.get().current.value;
    if (!meta || typeof navigator === 'undefined' || !('mediaSession' in navigator)) return;

    const artwork: MediaImage[] = [];
    if (meta.coverArtUrl) {
      artwork.push({ src: meta.coverArtUrl, sizes: '512x512', type: 'image/jpeg' });
    }

    navigator.mediaSession.metadata = new MediaMetadata({
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      artwork,
    });
  });

  effect(() => {
    if (typeof navigator === 'undefined' || !('mediaSession' in navigator)) return;
    const state = playbackCtx.get().state.value;
    navigator.mediaSession.playbackState = state === 'playing' ? 'playing' : 'paused';
  });

  if (typeof navigator !== 'undefined' && 'mediaSession' in navigator) {
    navigator.mediaSession.setActionHandler('play', () => {
      const t = trackCtx.get().current.value;
      if (t) actions.requestPlay(t);
    });
    navigator.mediaSession.setActionHandler('pause', () => actions.requestPause());
    navigator.mediaSession.setActionHandler('nexttrack', () => {
      actions.nextInQueue().catch(() => {});
    });
    navigator.mediaSession.setActionHandler('previoustrack', null);
    navigator.mediaSession.setActionHandler('seekto', null);
  }
}
