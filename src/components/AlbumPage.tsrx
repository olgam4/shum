import { track } from 'ripple';
import { actions } from '../actions';
import { formatTime } from '../state';
import { ctx, libraryCtx, routeCtx } from '../context';

export function AlbumPage() {
  const lib = libraryCtx.get();
  const rt = routeCtx.get();

  const albumId = ctx.selectedAlbum.id.value;
  const albumName = ctx.selectedAlbum.name.value;
  const artistName = ctx.selectedAlbum.artistName.value;

  const songs = track(() => lib.data.value.songs
    .filter(s => s.albumId === albumId)
    .sort((a, b) => a.track - b.track)
  );

  return <>
    <div class="album-page">
      <div class="album-header">
        <button class="back-btn" onClick={() => {
          actions.haptic('light');
          rt.current.value = 'library';
        }}>{'←'}</button>
        <div class="album-info">
          <div class="album-title">{albumName}</div>
          <div class="album-by">{artistName}</div>
        </div>
      </div>
      <div class="album-tracks">
        if (songs.value.length === 0) {
          <div class="empty-msg">{'No tracks found.'}</div>
        } else {
          for (const s of songs.value; index i) {
            <button class="track-row" data-even={i % 2 === 0} onClick={async () => {
              actions.haptic('light');
              actions.setQueue(s);
              const covUrl = await actions.getCoverArtUrl(s.coverArt);
              await actions.requestPlaySong(s, covUrl);
            }}>
              <span class="track-num">{`${String(s.track).padStart(2, '0')}`}</span>
              <span class="track-title">{s.title}</span>
              <span class="track-dur">{formatTime(s.duration)}</span>
              <span class="track-add" onClick={(e) => {
                e.stopPropagation();
                actions.haptic('selection');
                actions.addToQueue(s);
              }}>{'+'}</span>
            </button>
          }
        }
      </div>
    </div>

    <style>
      .album-page {
        display: flex;
        flex-direction: column;
        height: 100%;
      }

      .album-header {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        gap: 10px;
        padding: clamp(8px, 2vw, 14px);
        border-bottom: var(--border-width) solid var(--color-primary);
        background: var(--color-surface-elevated);
      }

      .back-btn {
        flex-shrink: 0;
        width: 36px;
        height: 36px;
        border: var(--border-width) solid var(--color-secondary);
        background: var(--color-surface);
        color: var(--color-secondary);
        font-family: var(--font-family);
        font-size: clamp(1rem, 3vw, 1.25rem);
        font-weight: 800;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .back-btn:active {
        transform: translate(1px, 1px);
      }

      .album-info {
        flex: 1;
        overflow: hidden;
      }

      .album-title {
        font-size: clamp(0.9rem, 2.5vw, 1.25rem);
        font-weight: 900;
        color: var(--color-secondary);
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .album-by {
        font-size: clamp(0.6rem, 1.4vw, 0.7rem);
        color: var(--color-text-muted);
        font-weight: 400;
        margin-top: 1px;
      }

      .album-tracks {
        flex: 1;
        overflow-y: auto;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-y: contain;
      }

      .track-row {
        display: grid;
        grid-template-columns: 26px 1fr auto auto;
        gap: 6px;
        align-items: center;
        width: 100%;
        min-height: 44px;
        padding: 4px clamp(8px, 2vw, 14px);
        box-sizing: border-box;
        border: none;
        border-bottom: 1px solid oklch(15% 0.02 260 / 0.06);
        background: transparent;
        cursor: pointer;
        color: var(--color-text);
        font-family: var(--font-family);
        text-align: left;
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .track-row[data-even='true'] {
        background: oklch(15% 0.02 260 / 0.015);
      }

      .track-row:active {
        background: oklch(15% 0.02 260 / 0.06);
      }

      .track-num {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        font-weight: 400;
        color: var(--color-text-muted);
        text-align: right;
        font-variant-numeric: tabular-nums;
      }

      .track-title {
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
        font-weight: 700;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .track-dur {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        font-weight: 400;
        color: var(--color-text-muted);
        text-align: right;
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
      }

      .track-add {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 28px;
        height: 28px;
        border: 2px solid var(--color-secondary);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        font-weight: 800;
        color: var(--color-secondary);
        cursor: pointer;
        -webkit-tap-highlight-color: transparent;
        -webkit-user-select: none;
        user-select: none;
      }

      .track-add:active {
        background: var(--color-secondary);
        color: var(--color-surface);
      }

      .empty-msg {
        text-align: center;
        padding: 48px 0;
        color: var(--color-text-muted);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
      }
    </style>
  </>;
}
