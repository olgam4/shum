import type { Tracked } from 'ripple';
import type { PlaybackState, TrackMeta } from '../types';
import { actions } from '../actions';
import { formatTime } from '../state';
import { IconChevronUp } from './icons/IconChevronUp.tsrx';

export function Player(&{ track, playbackState, progress, duration, progressPercent, volume, volumePercent, playerOpen }: {
  track: Tracked<TrackMeta | null>;
  playbackState: Tracked<PlaybackState>;
  progress: Tracked<number>;
  duration: Tracked<number>;
  progressPercent: Tracked<number>;
  volume: Tracked<number>;
  volumePercent: Tracked<number>;
  playerOpen: Tracked<boolean>;
}) {
  return <>
    <div class="player-overlay" onClick={() => {
      actions.haptic('light');
      actions.closePlayer();
    }}>
      <div class="player-sheet" onClick={(e) => e.stopPropagation()}>
        <button class="close-btn" onClick={() => {
          actions.haptic('light');
          actions.closePlayer();
        }}>
          <IconChevronUp />
        </button>

        <div class="player-content">
          <div class="album-art-container">
            if (track.value?.coverArtUrl) {
              <img class="album-art" src={track.value.coverArtUrl} alt={track.value.album} />
            } else {
              <div class="album-art-placeholder">
                <span class="placeholder-glyph" data-state={playbackState.value}>
                  {playbackState.value === 'playing' ? '⋆' : '□'}
                </span>
              </div>
            }
          </div>

          <div class="track-info">
            <h2 class="track-title">{track.value?.title ?? '—'}</h2>
            <p class="track-artist">{track.value?.artist ?? 'Unknown Artist'}</p>
            <p class="track-album">{track.value?.album ?? ''}</p>
          </div>

          <div class="progress-section">
            <div class="progress-bar-track">
              <div class="progress-bar-fill" style={{ '--pb': progressPercent.value }} />
            </div>
            <div class="progress-times">
              <span class="time-elapsed">{formatTime(progress.value)}</span>
              <span class="time-total">{formatTime(duration.value)}</span>
            </div>
          </div>

          <div class="transport-controls">
            <button class="ctrl-btn ctrl-btn--side" disabled>
              <span class="ctrl-glyph">{'◁◁'}</span>
            </button>

            if (playbackState.value === 'playing') {
              <button class="ctrl-btn ctrl-btn--primary" onClick={() => {
                actions.haptic('light');
                actions.requestPause();
              }}>
                <span class="ctrl-glyph">{'■'}</span>
              </button>
            } else {
              <button class="ctrl-btn ctrl-btn--primary" onClick={() => {
                actions.haptic('light');
                actions.requestPlay(track.value);
              }}>
                <span class="ctrl-glyph">{'▶'}</span>
              </button>
            }

            <button class="ctrl-btn ctrl-btn--side" disabled>
              <span class="ctrl-glyph">{'▷▷'}</span>
            </button>
          </div>

          <div class="volume-section">
            <span class="volume-label">{'VOL '}{volumePercent.value}{'%'}</span>
            <div class="volume-bar-track">
              <div class="volume-bar-fill" style={{ '--vol': volumePercent.value }} />
            </div>
            <button class="stop-btn" onClick={() => {
              actions.haptic('medium');
              actions.requestStop();
            }}>
              <span class="stop-glyph">{'⏹'}</span>
            </button>
          </div>

          <div class="status-bar">
            <span class="status-label" data-state={playbackState.value}>
              {playbackState.value.toUpperCase()}
            </span>
            <span class="status-dot" data-state={playbackState.value} />
          </div>
        </div>
      </div>
    </div>

    <style>
      .player-overlay {
        position: fixed;
        inset: 0;
        z-index: 200;
        background: oklch(97% 0.01 90 / 0.92);
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        padding-top: env(safe-area-inset-top, 0px);
        animation: overlay-in 0.2s ease;
      }

      @keyframes overlay-in {
        from { opacity: 0; }
        to { opacity: 1; }
      }

      .player-sheet {
        background: var(--color-surface-elevated);
        border-top: var(--border-width) solid var(--color-primary);
        max-height: 100%;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        -webkit-overflow-scrolling: touch;
        padding: clamp(8px, 2vw, 14px);
        padding-bottom: calc(env(safe-area-inset-bottom, 0px) + 32px);
        animation: sheet-up 0.25s ease;
      }

      @keyframes sheet-up {
        from { transform: translateY(100%); }
        to { transform: translateY(0); }
      }

      .close-btn {
        display: block;
        flex-shrink: 0;
        margin: 0 auto 4px auto;
        background: none;
        border: none;
        color: var(--color-text-muted);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        cursor: pointer;
        min-height: var(--tap-min);
        min-width: var(--tap-min);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .player-content {
        flex: 1;
        min-height: 0;
        overflow-y: auto;
        overscroll-behavior-y: contain;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: clamp(6px, 1.2vh, 12px);
        max-width: 420px;
        margin: 0 auto;
      }

      .album-art-container {
        width: clamp(120px, 45vw, 260px);
        height: clamp(120px, 45vw, 260px);
        flex-shrink: 0;
        border: var(--border-width) solid var(--color-secondary);
        overflow: hidden;
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--color-primary);
      }

      .album-art { width: 100%; height: 100%; object-fit: cover; display: block; }

      .album-art-placeholder {
        width: 100%; height: 100%;
        display: flex; align-items: center; justify-content: center;
        background: var(--color-surface);
      }

      .placeholder-glyph {
        font-size: clamp(3rem, 8vw, 5rem);
        color: var(--color-secondary);
        opacity: 0.5;
      }

      .placeholder-glyph[data-state='playing'] {
        opacity: 1;
        color: var(--color-secondary);
        animation: glyph-pulse 1.4s ease-in-out infinite;
      }

      .placeholder-glyph[data-state='buffering'] {
        color: var(--color-tertiary);
        animation: glyph-pulse 0.6s step-end infinite;
      }

      @keyframes glyph-pulse {
        0%, 100% { opacity: 0.4; transform: scale(1); }
        50% { opacity: 1; transform: scale(1.12); }
      }

      .track-info { width: 100%; text-align: center; }

      .track-title {
        font-size: clamp(1.25rem, 4vw, 1.75rem);
        font-weight: 800;
        color: var(--color-secondary);
        margin: 0;
      }

      .track-artist {
        font-size: clamp(0.875rem, 2.5vw, 1.125rem);
        color: var(--color-secondary);
        font-weight: 700;
        margin: 4px 0 0 0;
      }

      .track-album {
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        color: var(--color-text-muted);
        margin: 2px 0 0 0;
      }

      .progress-section { width: 100%; display: flex; flex-direction: column; gap: 6px; }

      .progress-bar-track {
        width: 100%; height: 10px;
        border: var(--border-width) solid var(--color-secondary);
        background: var(--color-surface);
        overflow: hidden;
      }

      .progress-bar-fill {
        height: 100%;
        width: calc(var(--pb) * 1%);
        background: var(--color-primary);
        transition: width 0.2s linear;
      }

      .progress-times {
        display: flex; justify-content: space-between;
        font-size: clamp(0.625rem, 1.5vw, 0.75rem);
        font-weight: 700; letter-spacing: 0.06em;
      }

      .time-elapsed { color: var(--color-text); }
      .time-total { color: var(--color-text-muted); }

      .transport-controls {
        display: flex; align-items: center; justify-content: center;
        gap: clamp(16px, 5vw, 36px);
      }

      .ctrl-btn {
        display: flex; align-items: center; justify-content: center;
        border: var(--border-width) solid currentColor;
        background: var(--color-surface);
        cursor: pointer;
        transition: transform 0.05s ease, box-shadow 0.05s ease;
        padding: 0;
        color: var(--color-text);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .ctrl-btn:active { transform: translate(2px, 2px); box-shadow: none !important; }
      .ctrl-btn:disabled { opacity: 0.25; cursor: not-allowed; }

      .ctrl-btn--primary {
        width: clamp(52px, 14vw, 72px);
        height: clamp(52px, 14vw, 72px);
        border-color: var(--color-secondary);
        box-shadow: 6px 6px 0px var(--color-primary);
        background: var(--color-surface-elevated);
      }

      .ctrl-btn--side {
        width: clamp(36px, 9vw, 48px);
        height: clamp(36px, 9vw, 48px);
        border-color: var(--color-primary);
        box-shadow: 3px 3px 0px oklch(52% 0.32 262 / 0.6);
      }

      .ctrl-glyph { font-size: clamp(1rem, 3vw, 1.5rem); line-height: 1; }
      .ctrl-btn--primary .ctrl-glyph { font-size: clamp(1.5rem, 4vw, 2rem); }

      .volume-section {
        width: 100%; display: flex; align-items: center; gap: 10px;
      }

      .volume-label {
        font-size: clamp(0.625rem, 1.5vw, 0.75rem);
        font-weight: 800; letter-spacing: 0.08em;
        color: var(--color-secondary);
        white-space: nowrap; min-width: 52px;
      }

      .volume-bar-track {
        flex: 1; height: 8px;
        border: 2px solid var(--color-primary);
        background: var(--color-surface);
        overflow: hidden;
      }

      .volume-bar-fill {
        height: 100%;
        width: calc(var(--vol) * 1%);
        background: var(--color-secondary);
        transition: width 0.15s ease;
      }

      .stop-btn {
        display: flex; align-items: center; justify-content: center;
        width: clamp(32px, 8vw, 44px);
        height: clamp(32px, 8vw, 44px);
        border: var(--border-width) solid var(--color-tertiary);
        box-shadow: 3px 3px 0px var(--color-primary);
        background: var(--color-surface);
        cursor: pointer;
        transition: transform 0.05s ease, box-shadow 0.05s ease;
        padding: 0; color: var(--color-tertiary);
        -webkit-tap-highlight-color: transparent; outline: none;
      }

      .stop-btn:active { transform: translate(2px, 2px); box-shadow: none !important; }
      .stop-glyph { font-size: clamp(0.875rem, 2.5vw, 1.125rem); line-height: 1; }

      .status-bar {
        width: 100%; display: flex; align-items: center; justify-content: space-between;
        padding-top: 6px;
        flex-shrink: 0;
        border-top: 2px solid oklch(15% 0.02 260 / 0.1);
      }

      .status-label {
        font-size: clamp(0.625rem, 1.5vw, 0.6875rem);
        font-weight: 800; letter-spacing: 0.12em;
        color: var(--color-text-muted);
      }

      .status-label[data-state='playing'] { color: var(--color-secondary); }
      .status-label[data-state='paused'] { color: var(--color-tertiary); }
      .status-label[data-state='buffering'] {
        color: var(--color-tertiary);
        animation: status-blink 0.8s step-end infinite;
      }

      @keyframes status-blink { 50% { opacity: 0; } }

      .status-dot {
        width: 10px; height: 10px;
        border: 2px solid oklch(15% 0.02 260 / 0.3);
        background: transparent;
      }

      .status-dot[data-state='playing'] {
        background: var(--color-secondary);
        border-color: var(--color-secondary);
        box-shadow: 0 0 8px oklch(52% 0.32 262 / 0.6);
      }

      .status-dot[data-state='paused'] {
        background: var(--color-tertiary);
        border-color: var(--color-tertiary);
      }

      .status-dot[data-state='buffering'] {
        background: var(--color-tertiary);
        border-color: var(--color-tertiary);
        animation: status-blink 0.5s step-end infinite;
      }
    </style>
  </>;
}
