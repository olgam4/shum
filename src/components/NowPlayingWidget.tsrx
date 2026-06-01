import type { Tracked } from 'ripple';
import type { PlaybackState, TrackMeta } from '../types';
import { actions } from '../actions';

export function NowPlayingWidget(&{ track, playbackState, artist, progressPercent, playerOpen, route }: {
  track: Tracked<TrackMeta | null>;
  playbackState: Tracked<PlaybackState>;
  artist: string;
  progressPercent: Tracked<number>;
  playerOpen: Tracked<boolean>;
  route: Tracked<any>;
}) {
  return <>
    <div class="widget" onClick={() => {
      actions.haptic('light');
      actions.openPlayer();
    }}>
      <div class="widget-progress-bar">
        <div class="widget-progress-fill" style={{ '--p': progressPercent.value }} />
      </div>
      <div class="widget-inner">
        <div class="widget-info">
          <span class="widget-title">{track.value?.title ?? '—'}</span>
          <span class="widget-artist">{artist}</span>
        </div>
        <button class="widget-play-btn" onClick={(e) => {
          e.stopPropagation();
          actions.haptic('light');
          if (playbackState.value === 'playing') actions.requestPause();
          else actions.requestPlay(track.value);
        }}>
          {playbackState.value === 'playing' ? '■' : '▶'}
        </button>
      </div>
    </div>

    <style>
      .widget {
        width: 100%;
        flex-shrink: 0;
        height: var(--widget-height);
        background: var(--color-surface-elevated);
        border-top: var(--border-width) solid var(--color-primary);
        cursor: pointer;
        z-index: 99;
        -webkit-tap-highlight-color: transparent;
      }

      .widget:active {
        background: oklch(88% 0.02 90 / 0.95);
      }

      .widget-progress-bar {
        height: 3px;
        background: var(--color-surface);
      }

      .widget-progress-fill {
        height: 100%;
        width: calc(var(--p) * 1%);
        background: var(--color-primary);
        transition: width 0.3s linear;
      }

      .widget-inner {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 clamp(12px, 3vw, 16px);
        min-height: var(--widget-height);
      }

      .widget-info {
        display: flex;
        flex-direction: column;
        gap: 1px;
        overflow: hidden;
        flex: 1;
      }

      .widget-title {
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        font-weight: 800;
        color: var(--color-text);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .widget-artist {
        font-size: clamp(0.6rem, 1.4vw, 0.7rem);
        color: var(--color-text-muted);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .widget-play-btn {
        flex-shrink: 0;
        width: var(--tap-min);
        height: var(--tap-min);
        border: var(--border-width) solid var(--color-secondary);
        background: var(--color-surface);
        color: var(--color-text);
        font-size: clamp(0.875rem, 2.5vw, 1rem);
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        box-shadow: 2px 2px 0px var(--color-primary);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .widget-play-btn:active {
        transform: translate(1px, 1px);
        box-shadow: none;
      }
    </style>
  </>;
}
