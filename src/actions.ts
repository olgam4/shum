import { invoke } from '@tauri-apps/api/core';
import type { TrackMeta } from './types';

export const actions = {
  requestPlay(track: TrackMeta | null) {
    if (track) {
      return invoke('resume');
    }
    return invoke('playTrack', {
      id: 'default',
      title: 'Test Tone',
      artist: 'SHUM',
      album: 'System',
      durationSecs: 180,
      coverArtUrl: null,
      streamUrl: 'https://example.com/tone.mp3',
    });
  },

  requestPause() {
    return invoke('pause');
  },

  requestStop() {
    return invoke('stop');
  },

  requestSeek(positionSecs: number) {
    return invoke('seek', { positionSecs });
  },

  requestSetVolume(volume: number) {
    return invoke('setVolume', { volume: Math.max(0, Math.min(1, volume)) });
  },
};
