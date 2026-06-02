import type { PlaybackState, TrackMeta } from '../types';
import { nowPlaying, requestPlay, requestPause, requestStop, haptic } from '../stores/now-playing';
import { router, navigateToArtist, navigateToAlbum } from '../stores/router';
import { formatTime, computed } from '../state';
import { DataCell } from './DataCell.tsrx';
import { IconButton } from './IconButton.tsrx';
import { Badge } from './Badge.tsrx';
import { IconChevronUp } from './icons/IconChevronUp.tsrx';

export function Player() {
  const tk = nowPlaying.track;
  const pb = nowPlaying.playback;
  const po = nowPlaying.playerOpen;
  const pc = nowPlaying.playerClosing;
  const rt = router.state;

  const closePlayer = () => {
    haptic('light');
    pc.closing.value = true;
    setTimeout(() => {
      pc.closing.value = false;
      po.open.value = false;
    }, 250);
  };

  return <>
    <div class={`player-overlay${pc.closing.value ? ' closing' : ''}`} onClick={closePlayer}>
      <div class={`player-sheet${pc.closing.value ? ' closing' : ''}`} onClick={(e: Event) => e.stopPropagation()}>
        <button class="close-btn" onClick={closePlayer}>
          <IconChevronUp />
        </button>

        <div class="player-content">
          <div class="album-art-container">
            if (tk.current.value?.coverArtUrl) {
              <img class="album-art" src={tk.current.value.coverArtUrl} alt={tk.current.value.album} />
            } else {
              <div class="album-art-placeholder">
                <span class="placeholder-glyph" data-state={pb.state.value}>
                  {pb.state.value === 'playing' ? '\u22C6' : '\u25A1'}
                </span>
              </div>
            }
            <div class="album-art-badge">
              <Badge variant="accent">{'LOSSLESS AUDIO'}</Badge>
            </div>
          </div>

          <div class="track-info">
            <h2 class="track-title">{tk.current.value?.title ?? '\u2014'}</h2>
            <button class="track-artist-btn" onClick={() => {
              if (tk.current.value?.artistId) {
                haptic('light');
                pc.closing.value = true;
                navigateToArtist(tk.current.value.artistId, tk.current.value.artist);
                setTimeout(() => {
                  pc.closing.value = false;
                  po.open.value = false;
                }, 250);
              }
            }}>{tk.current.value?.artist ?? 'Unknown Artist'}</button>
            <button class="track-album-btn" onClick={() => {
              if (tk.current.value?.albumId) {
                haptic('light');
                pc.closing.value = true;
                navigateToAlbum(tk.current.value.albumId, tk.current.value.album, tk.current.value?.artistId ?? '', tk.current.value?.artist ?? '');
                setTimeout(() => {
                  pc.closing.value = false;
                  po.open.value = false;
                }, 250);
              }
            }}>{tk.current.value?.album ?? ''}</button>
            if (tk.current.value?.suffix) {
              <p class="track-format">{`${tk.current.value.suffix.toUpperCase()} \u00B7 ${tk.current.value.contentType}`}</p>
            }
          </div>

          <div class="bento-grid">
            <DataCell label="Sample Rate" value="48 kHz" />
            <DataCell label="Bit Depth" value="16-bit" />
            <DataCell label="Format" value={tk.current.value?.suffix?.toUpperCase() ?? '\u2014'} />
            <div class="bento-full">
              <DataCell label="Source" value={tk.current.value?.contentType ?? '\u2014'} />
            </div>
          </div>

          <div class="progress-section">
            <div class="progress-bar-track">
              <div class="progress-bar-fill" style={{ '--pb': computed.progressPct.value }}>
                <div class="progress-bar-knob" />
              </div>
            </div>
            <div class="progress-times">
              <span class="time-elapsed">{formatTime(pb.progress.value)}</span>
              <span class="time-total">{`-${formatTime(pb.duration.value - pb.progress.value)}`}</span>
            </div>
          </div>

          <div class="transport-controls">
            <IconButton icon="\u25C1\u25C1" size="lg" onClick={() => {}} />
            if (pb.state.value === 'playing') {
              <IconButton icon="\u23F8" variant="tertiary" size="xl" onClick={() => {
                haptic('light');
                requestPause();
              }} />
            } else {
              <IconButton icon="\u25B6" variant="primary" size="xl" onClick={() => {
                haptic('light');
                requestPlay(tk.current.value);
              }} />
            }
            <IconButton icon="\u25B7\u25B7" size="lg" onClick={() => {}} />
          </div>

          <div class="status-bar">
            <span class="status-label" data-state={pb.state.value}>
              {pb.state.value.toUpperCase()}
            </span>
            <span class="status-dot" data-state={pb.state.value} />
            <button class="stop-btn" onClick={() => {
              haptic('medium');
              requestStop();
            }}>
              <span class="stop-glyph">{'\u23F9'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <style>
      .player-overlay {
        position: fixed;
        inset: 0;
        z-index: 200;
        background: var(--color-surface);
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        padding: env(safe-area-inset-top, 16px) env(safe-area-inset-right, 16px) env(safe-area-inset-bottom, 16px) env(safe-area-inset-left, 16px);
        animation: overlay-in 0.2s ease;
      }

      @keyframes overlay-in {
        from { opacity: 0; }
        to { opacity: 1; }
      }

      .player-overlay.closing {
        animation: overlay-out 0.25s ease forwards;
      }

      @keyframes overlay-out {
        from { opacity: 1; }
        to { opacity: 0; }
      }

      .player-sheet {
        background: var(--color-surface-elevated);
        border-top: var(--border-width) solid var(--color-text);
        box-shadow: 0 -4px 0 var(--color-text);
        max-height: 100%;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        animation: sheet-up 0.25s ease;
      }

      @keyframes sheet-up {
        from { transform: translateY(100%); }
        to { transform: translateY(0); }
      }

      .player-sheet.closing {
        animation: sheet-down 0.25s ease forwards;
      }

      @keyframes sheet-down {
        from { transform: translateY(0); }
        to { transform: translateY(100%); }
      }

      .close-btn {
        display: block;
        flex-shrink: 0;
        margin: 0 auto 4px auto;
        padding-top: 8px;
        background: none;
        border: none;
        color: var(--color-text-muted);
        font-size: clamp(0.875rem, 2.5vw, 1rem);
        cursor: pointer;
        min-height: var(--tap-min);
        min-width: var(--tap-min);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .player-content {
        flex: 1;
        min-height: 0;
        display: flex;
        flex-direction: column;
        align-items: stretch;
        gap: clamp(6px, 1.2vh, 12px);
        padding: 0 clamp(16px, 4vw, 32px) clamp(16px, 4vw, 32px);
        overflow-y: auto;
        -webkit-overflow-scrolling: touch;
      }

      .album-art-container {
        width: clamp(160px, 50vw, 280px);
        height: clamp(160px, 50vw, 280px);
        flex-shrink: 0;
        align-self: center;
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset-lg) var(--shadow-offset-lg) 0 var(--color-text);
        overflow: hidden;
        position: relative;
      }

      .album-art { width: 100%; height: 100%; object-fit: cover; display: block; }

      .album-art-placeholder {
        width: 100%; height: 100%;
        display: flex; align-items: center; justify-content: center;
        background: var(--color-primary-container);
      }

      .placeholder-glyph {
        font-size: clamp(3rem, 8vw, 5rem);
        color: var(--color-on-primary-container);
        opacity: 0.5;
      }

      .placeholder-glyph[data-state='playing'] {
        opacity: 1;
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

      .album-art-badge {
        position: absolute;
        top: 8px;
        right: 8px;
      }

      .track-info { text-align: center; }

      .track-title {
        font-family: var(--font-family);
        font-size: var(--fs-headline-lg);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--color-text);
        margin: 0;
        line-height: var(--lh-headline);
      }

      .track-artist-btn {
        display: block;
        width: 100%;
        font-family: var(--font-family);
        font-size: var(--fs-body-bold);
        color: var(--color-secondary);
        font-weight: 700;
        margin: 6px 0 0 0;
        padding: 0;
        border: none;
        background: transparent;
        cursor: pointer;
        text-align: center;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        text-decoration: underline;
        text-decoration-color: var(--color-secondary-container);
        text-underline-offset: 3px;
      }

      .track-artist-btn:active {
        opacity: 0.6;
        transform: scale(0.97);
      }

      .track-album-btn {
        display: block;
        width: 100%;
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        color: var(--color-text-muted);
        font-weight: 400;
        margin: 3px 0 0 0;
        padding: 0;
        border: none;
        background: transparent;
        cursor: pointer;
        text-align: center;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        text-decoration: underline;
        text-decoration-color: var(--color-outline);
        text-underline-offset: 3px;
      }

      .track-album-btn:active {
        opacity: 0.6;
        transform: scale(0.97);
      }

      .track-format {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
        margin: 4px 0 0 0;
        opacity: 0.6;
      }

      .bento-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: var(--unit);
        margin-top: 6px;
      }

      .bento-full {
        grid-column: 1 / -1;
      }

      .progress-section { display: flex; flex-direction: column; gap: 6px; }

      .progress-bar-track {
        width: 100%; height: 20px;
        border: var(--border-width) solid var(--color-text);
        background: var(--color-surface);
        overflow: hidden;
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
      }

      .progress-bar-fill {
        height: 100%;
        width: calc(var(--pb) * 1%);
        background: var(--color-primary);
        transition: width 0.2s linear;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        border-right: var(--border-width) solid var(--color-text);
      }

      .progress-bar-knob {
        width: 4px;
        height: 12px;
        background: var(--color-text);
        margin-right: 2px;
      }

      .progress-times {
        display: flex; justify-content: space-between;
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.06em;
      }

      .time-elapsed { color: var(--color-text); }
      .time-total { color: var(--color-text-muted); }

      .transport-controls {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: clamp(12px, 3vw, 24px);
        margin-top: 8px;
      }

      .stop-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 36px;
        height: 36px;
        border: var(--border-width) solid var(--color-tertiary);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface);
        cursor: pointer;
        transition: transform 0.05s ease, box-shadow 0.05s ease;
        padding: 0;
        color: var(--color-tertiary);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .stop-btn:active {
        transform: translate(var(--shadow-offset), var(--shadow-offset));
        box-shadow: none;
      }

      .stop-glyph {
        font-size: clamp(0.875rem, 2.5vw, 1rem);
        line-height: 1;
      }

      .status-bar {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;
        padding-top: 8px;
        flex-shrink: 0;
        border-top: var(--border-width) solid var(--color-text);
      }

      .status-label {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 800;
        letter-spacing: 0.12em;
        color: var(--color-text-muted);
      }

      .status-label[data-state='playing'] { color: var(--color-secondary); }
      .status-label[data-state='paused'] { color: var(--color-tertiary); }
      .status-label[data-state='buffering'] {
        color: var(--color-tertiary);
        animation: status-blink 0.8s step-end infinite;
      }

      .status-label[data-state='error'] {
        color: var(--color-tertiary);
        animation: status-blink 0.4s step-end infinite;
      }

      @keyframes status-blink { 50% { opacity: 0; } }

      .status-dot {
        width: 12px; height: 12px;
        border: 2px solid var(--color-outline);
        background: transparent;
      }

      .status-dot[data-state='playing'] {
        background: var(--color-secondary);
        border-color: var(--color-secondary);
        box-shadow: 0 0 10px var(--color-secondary-container);
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

      .status-dot[data-state='error'] {
        background: var(--color-tertiary);
        border-color: var(--color-tertiary);
        animation: status-blink 0.25s step-end infinite;
      }
    </style>
  </>;
}
