import type { LibrarySong } from '../types';
import { formatTime } from '../state';

export function TrackRow(
  { song, index, active, onPlay, onAdd }: {
    song: LibrarySong;
    index: number;
    active?: boolean;
    onPlay?: () => void;
    onAdd?: (e: Event) => void;
  },
) {
  return <>
    <button
      class={`track-row${active ? ' track-row--active' : ''}`}
      data-even={index % 2 === 0}
      style={{ '--i': String(index) }}
      onClick={() => onPlay?.()}
    >
      <span class="track-row__num">{`${String(song.track).padStart(2, '0')}`}</span>
      <span class="track-row__title">{song.title}</span>
      <span class="track-row__artist">{song.artist}</span>
      <span class="track-row__album">{song.album}</span>
      <span class="track-row__duration">{formatTime(song.duration)}</span>
      <span class="track-row__add" onClick={(e: Event) => onAdd?.(e)}>{'+'}</span>
    </button>
    <style>
      .track-row {
        display: grid;
        grid-template-columns: 26px 2fr 1.3fr 1fr auto auto;
        gap: 4px;
        align-items: center;
        width: 100%;
        min-height: var(--tap-min);
        padding: 4px clamp(8px, 2vw, 14px);
        box-sizing: border-box;
        border: none;
        border-bottom: 2px solid var(--color-surface-variant);
        background: transparent;
        cursor: pointer;
        color: var(--color-text);
        font-family: var(--font-family);
        text-align: left;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        transition: background 0.1s ease, color 0.1s ease;
      }

      .track-row[data-even='true'] {
        background: var(--color-surface-variant);
      }

      .track-row:active {
        background: var(--color-primary);
        color: var(--color-on-primary);
      }

      .track-row--active {
        background: var(--color-primary-container) !important;
        color: var(--color-on-primary-container);
      }

      .track-row {
        animation: track-enter 0.35s ease both;
        animation-delay: calc(var(--i, 0) * 20ms);
      }

      @keyframes track-enter {
        from { opacity: 0; transform: translateY(6px); }
        to { opacity: 1; transform: translateY(0); }
      }

      .track-row__num {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        font-weight: 400;
        color: var(--color-text-muted);
        text-align: right;
        font-variant-numeric: tabular-nums;
      }

      .track-row__title {
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
        font-weight: 700;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .track-row__artist {
        font-size: clamp(0.55rem, 1.3vw, 0.65rem);
        color: var(--color-text-muted);
        font-weight: 400;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .track-row__album {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        color: var(--color-text-muted);
        font-weight: 400;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        display: none;
      }

      @media (min-width: 400px) {
        .track-row__album {
          display: block;
        }
      }

      .track-row__duration {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        font-weight: 400;
        color: var(--color-text-muted);
        text-align: right;
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
      }

      .track-row__add {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 28px;
        height: 28px;
        margin-left: 4px;
        border: 2px solid var(--color-secondary);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        font-weight: 800;
        color: var(--color-secondary);
        cursor: pointer;
        -webkit-tap-highlight-color: transparent;
        -webkit-user-select: none;
        user-select: none;
      }

      .track-row__add:active {
        background: var(--color-secondary);
        color: var(--color-on-secondary);
        transform: scale(0.9);
      }
    </style>
  </>;
}
