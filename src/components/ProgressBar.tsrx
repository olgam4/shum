import type { Tracked } from 'ripple';
import { formatTime } from '../state';

export function ProgressBar(&{ progressPercent, progress, duration }: {
  progressPercent: Tracked<number>;
  progress: Tracked<number>;
  duration: Tracked<number>;
}) {
  return <>
    <div class="pb-root">
      <div class="progress-bar-track">
        <div class="progress-bar-fill" style={{ '--pb': progressPercent }} />
      </div>
      <div class="progress-times">
        <span class="time-elapsed">{formatTime(progress)}</span>
        <span class="time-total">{formatTime(duration)}</span>
      </div>
    </div>

    <style>
      .pb-root {
        width: 100%;
        display: flex;
        flex-direction: column;
        gap: 6px;
      }

      .progress-bar-track {
        width: 100%;
        height: 10px;
        border: var(--shum-border) solid var(--shum-color-accent);
        background: var(--shum-color-surface);
        position: relative;
        overflow: hidden;
      }

      .progress-bar-fill {
        height: 100%;
        width: calc(var(--pb) * 1%);
        background: var(--shum-color-brand);
        transition: width 0.2s linear;
      }

      .progress-times {
        display: flex;
        justify-content: space-between;
        font-size: clamp(0.625rem, 1.5vw, 0.75rem);
        font-weight: 700;
        letter-spacing: 0.06em;
      }

      .time-elapsed {
        color: var(--shum-color-brand);
      }

      .time-total {
        color: var(--shum-color-text-muted);
      }
    </style>
  </>;
}
