import type { Tracked } from 'ripple';
import type { PlaybackState } from '../types';

export function StatusBar(&{ playbackState }: {
  playbackState: Tracked<PlaybackState>;
}) {
  return <>
    <div class="sb-root">
      <span class="status-label" data-state={playbackState}>
        {playbackState.toUpperCase()}
      </span>
      <span class="status-dot" data-state={playbackState} />
    </div>

    <style>
      .sb-root {
        width: 100%;
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding-top: 10px;
        border-top: 2px solid oklch(98% 0 0 / 0.1);
      }

      .status-label {
        font-size: clamp(0.625rem, 1.5vw, 0.6875rem);
        font-weight: 800;
        letter-spacing: 0.12em;
        color: var(--shum-color-text-muted);
      }

      .status-label[data-state='playing'] {
        color: var(--shum-color-accent);
      }

      .status-label[data-state='paused'] {
        color: var(--shum-color-brand);
      }

      .status-label[data-state='buffering'] {
        color: var(--shum-color-danger);
        animation: status-blink 0.8s step-end infinite;
      }

      @keyframes status-blink {
        50% { opacity: 0; }
      }

      .status-dot {
        width: 10px;
        height: 10px;
        border: 2px solid oklch(98% 0 0 / 0.3);
        background: transparent;
      }

      .status-dot[data-state='playing'] {
        background: var(--shum-color-accent);
        border-color: var(--shum-color-accent);
        box-shadow: 0 0 8px oklch(52% 0.32 262 / 0.6);
      }

      .status-dot[data-state='paused'] {
        background: var(--shum-color-brand);
        border-color: var(--shum-color-brand);
      }

      .status-dot[data-state='buffering'] {
        background: var(--shum-color-danger);
        border-color: var(--shum-color-danger);
        animation: status-blink 0.5s step-end infinite;
      }
    </style>
  </>;
}
