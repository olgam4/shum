import type { Tracked } from 'ripple';
import { actions } from '../actions';

export function VolumeControl(&{ volumePercent }: {
  volumePercent: Tracked<number>;
}) {
  return <>
    <div class="vc-root">
      <span class="volume-label">{'VOL '}{volumePercent}{'%'}</span>
      <div class="volume-bar-track">
        <div class="volume-bar-fill" style={{ '--vol': volumePercent }} />
      </div>
      <button
        class="stop-btn"
        aria-label="Stop"
        onClick={() => actions.requestStop()}
      >
        <span class="stop-glyph">{'⏹'}</span>
      </button>
    </div>

    <style>
      .vc-root {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 10px;
      }

      .volume-label {
        font-size: clamp(0.625rem, 1.5vw, 0.75rem);
        font-weight: 800;
        letter-spacing: 0.08em;
        color: var(--shum-color-brand);
        white-space: nowrap;
        min-width: 52px;
      }

      .volume-bar-track {
        flex: 1;
        height: 8px;
        border: 2px solid var(--shum-color-brand);
        background: var(--shum-color-surface);
        overflow: hidden;
      }

      .volume-bar-fill {
        height: 100%;
        width: calc(var(--vol) * 1%);
        background: var(--shum-color-accent);
        transition: width 0.15s ease;
      }

      .stop-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: clamp(32px, 8vw, 44px);
        height: clamp(32px, 8vw, 44px);
        border: var(--shum-border) solid var(--shum-color-danger);
        box-shadow: 3px 3px 0px var(--shum-color-brand);
        background: var(--shum-color-surface);
        cursor: pointer;
        transition: transform 0.05s ease, box-shadow 0.05s ease;
        padding: 0;
        color: var(--shum-color-danger);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .stop-btn:active {
        transform: translate(2px, 2px);
        box-shadow: none !important;
      }

      .stop-glyph {
        font-size: clamp(0.875rem, 2.5vw, 1.125rem);
        line-height: 1;
      }
    </style>
  </>;
}
