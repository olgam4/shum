import type { Tracked } from 'ripple';
import type { PlaybackState, TrackMeta } from '../types';
import { actions } from '../actions';

export function TransportControls(&{ playbackState, track }: {
  playbackState: Tracked<PlaybackState>;
  track: Tracked<TrackMeta | null>;
}) {
  return <>
    <div class="tc-root">
      <button class="ctrl-btn ctrl-btn--side" disabled aria-label="Previous">
        <span class="ctrl-glyph">{'◁◁'}</span>
      </button>

      if (playbackState === 'playing') {
        <button
          class="ctrl-btn ctrl-btn--primary"
          aria-label="Pause"
          onClick={() => actions.requestPause()}
        >
          <span class="ctrl-glyph">{'■'}</span>
        </button>
      } else {
        <button
          class="ctrl-btn ctrl-btn--primary"
          aria-label="Play"
          onClick={() => actions.requestPlay(track)}
        >
          <span class="ctrl-glyph">{'▶'}</span>
        </button>
      }

      <button class="ctrl-btn ctrl-btn--side" disabled aria-label="Next">
        <span class="ctrl-glyph">{'▷▷'}</span>
      </button>
    </div>

    <style>
      .tc-root {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: clamp(16px, 5vw, 36px);
      }

      .ctrl-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        border: var(--shum-border) solid currentColor;
        background: var(--shum-color-surface);
        cursor: pointer;
        transition: transform 0.05s ease, box-shadow 0.05s ease;
        padding: 0;
        color: var(--shum-color-text);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .ctrl-btn:active {
        transform: translate(2px, 2px);
        box-shadow: none !important;
      }

      .ctrl-btn:disabled {
        opacity: 0.25;
        cursor: not-allowed;
      }

      .ctrl-btn--primary {
        width: clamp(64px, 16vw, 88px);
        height: clamp(64px, 16vw, 88px);
        border-color: var(--shum-color-accent);
        box-shadow: 6px 6px 0px var(--shum-color-brand);
        background: var(--shum-color-surface-raised);
      }

      .ctrl-btn--side {
        width: clamp(44px, 10vw, 56px);
        height: clamp(44px, 10vw, 56px);
        border-color: var(--shum-color-brand);
        box-shadow: 3px 3px 0px oklch(52% 0.32 262 / 0.6);
      }

      .ctrl-glyph {
        font-size: clamp(1rem, 3vw, 1.5rem);
        line-height: 1;
      }

      .ctrl-btn--primary .ctrl-glyph {
        font-size: clamp(1.5rem, 4vw, 2rem);
      }
    </style>
  </>;
}
