import { track } from 'ripple';
import { actions } from '../actions';
import { ctx, libraryCtx, routeCtx } from '../context';

export function ArtistPage() {
  const lib = libraryCtx.get();
  const rt = routeCtx.get();

  const artistId = ctx.selectedArtist.id.value;
  const artistName = ctx.selectedArtist.name.value;

  const albums = track(() => lib.data.value.albums.filter(a => a.artistId === artistId));

  return <>
    <div class="artist-page">
      <div class="artist-header">
        <button class="back-btn" onClick={() => {
          actions.haptic('light');
          rt.current.value = 'library';
        }}>{'←'}</button>
        <div class="artist-name">{artistName}</div>
        <div class="artist-album-count">{`${albums.value.length} albums`}</div>
      </div>
      <div class="album-grid">
        if (albums.value.length === 0) {
          <div class="empty-msg">{'No albums found.'}</div>
        } else {
          for (const a of albums.value) {
            <button class="album-tile" onClick={() => {
              actions.haptic('light');
              ctx.selectedAlbum.id.value = a.id;
              ctx.selectedAlbum.name.value = a.name;
              ctx.selectedAlbum.artistId.value = a.artistId;
              ctx.selectedAlbum.artistName.value = artistName;
              rt.current.value = 'album';
            }}>
              <div class="tile-art">{'◉'}</div>
              <div class="tile-name">{a.name}</div>
              <div class="tile-meta">{`${a.year || '—'} · ${a.songCount} songs`}</div>
            </button>
          }
        }
      </div>
    </div>

    <style>
      .artist-page {
        display: flex;
        flex-direction: column;
        height: 100%;
      }

      .artist-header {
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

      .artist-name {
        flex: 1;
        font-size: clamp(1rem, 3vw, 1.5rem);
        font-weight: 900;
        color: var(--color-secondary);
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .artist-album-count {
        flex-shrink: 0;
        font-size: clamp(0.6rem, 1.4vw, 0.7rem);
        color: var(--color-text-muted);
        font-weight: 700;
      }

      .album-grid {
        flex: 1;
        overflow-y: auto;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-y: contain;
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(clamp(140px, 40vw, 200px), 1fr));
        gap: clamp(8px, 2vw, 14px);
        padding: clamp(8px, 2vw, 14px);
        align-content: start;
      }

      .album-tile {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 6px;
        padding: clamp(10px, 2.5vw, 16px);
        border: var(--border-width) solid var(--color-secondary);
        box-shadow: 3px 3px 0px var(--color-primary);
        background: var(--color-surface-elevated);
        cursor: pointer;
        text-align: center;
        font-family: var(--font-family);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .album-tile:active {
        transform: translate(1px, 1px);
        box-shadow: none;
      }

      .tile-art {
        font-size: clamp(2rem, 8vw, 3.5rem);
        color: var(--color-secondary);
        line-height: 1;
      }

      .tile-name {
        font-size: clamp(0.65rem, 1.5vw, 0.8rem);
        font-weight: 800;
        color: var(--color-text);
        overflow: hidden;
        text-overflow: ellipsis;
        width: 100%;
        white-space: nowrap;
      }

      .tile-meta {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        color: var(--color-text-muted);
        font-weight: 400;
      }

      .empty-msg {
        grid-column: 1 / -1;
        text-align: center;
        padding: 32px 0;
        color: var(--color-text-muted);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
      }
    </style>
  </>;
}
