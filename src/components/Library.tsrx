import type { Tracked } from 'ripple';
import type { ConnectionStatus, Route, SearchResult, LibrarySong, LibraryAlbum, LibraryArtist } from '../types';
import { actions } from '../actions';

export function Library(&{ library, connection, route }: {
  library: Tracked<SearchResult>;
  connection: Tracked<ConnectionStatus>;
  route: Tracked<Route>;
}) {
  return <>
    <div class="library">
      if (connection !== 'connected') {
        <div class="no-connection">
          <p>{'Connect to a server to browse your library.'}</p>
          <button class="go-settings-btn" onClick={() => {
            actions.haptic('light');
            route.value = 'settings';
          }}>
            {'Go to Settings'}
          </button>
        </div>
      } else if (library.artists.length === 0 && library.albums.length === 0 && library.songs.length === 0) {
        <div class="empty-lib">
          <p>{'Library is empty.'}</p>
          <button class="sync-btn" onClick={() => {
            actions.haptic('medium');
            actions.syncLibrary();
          }}>
            {'Синхронизация'}
          </button>
        </div>
      } else {
        <div class="lib-content">
          <h3 class="section-title">{'Artists'} <span class="count">{`(${library.artists.length})`}</span></h3>
          <div class="scroll-row">
            for (const a of library.artists) {
              <div class="artist-chip">{a.name}</div>
            }
          </div>

          <h3 class="section-title">{'Albums'} <span class="count">{`(${library.albums.length})`}</span></h3>
          <div class="scroll-row">
            for (const a of library.albums) {
              <div class="album-chip">{a.name}</div>
            }
          </div>

          <h3 class="section-title">{'Songs'} <span class="count">{`(${library.songs.length})`}</span></h3>
          <div class="song-list">
            for (const s of library.songs) {
              <button class="song-row" onClick={() => {
                actions.haptic('light');
                actions.getStreamUrl(s.id).then((url) => {
                  const covUrl = `__COVER_${s.coverArt}`;
                  actions.requestPlayUrl(s, url, covUrl);
                });
              }}>
                <span class="song-title">{s.title}</span>
                <span class="song-artist">{s.artist}</span>
              </button>
            }
          </div>
        </div>
      }
    </div>

    <style>
      .library {
        padding: clamp(12px, 3vw, 20px);
        min-height: 100%;
      }

      .no-connection, .empty-lib {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 50vh;
        gap: 16px;
        text-align: center;
        color: var(--color-text-muted);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
      }

      .go-settings-btn, .sync-btn {
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-primary);
        background: var(--color-surface);
        color: var(--color-primary);
        font-family: var(--font-family);
        font-weight: 800;
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        letter-spacing: 0.06em;
        padding: 8px 20px;
        cursor: pointer;
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .go-settings-btn:active, .sync-btn:active {
        transform: translate(2px, 2px);
        box-shadow: none;
      }

      .section-title {
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        font-weight: 800;
        letter-spacing: 0.08em;
        color: var(--color-primary);
        margin: 16px 0 8px 0;
      }

      .count {
        color: var(--color-text-muted);
        font-weight: 400;
      }

      .scroll-row {
        display: flex;
        gap: 8px;
        overflow-x: auto;
        padding-bottom: 4px;
        -webkit-overflow-scrolling: touch;
      }

      .artist-chip, .album-chip {
        flex-shrink: 0;
        padding: 6px 14px;
        border: 2px solid var(--color-secondary);
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
        font-weight: 700;
        color: var(--color-text);
        background: var(--color-surface-elevated);
        white-space: nowrap;
      }

      .song-list {
        display: flex;
        flex-direction: column;
      }

      .song-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        min-height: var(--tap-min);
        padding: 8px 4px;
        border: none;
        border-bottom: 1px solid oklch(98% 0 0 / 0.08);
        background: transparent;
        cursor: pointer;
        color: var(--color-text);
        font-family: var(--font-family);
        text-align: left;
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .song-row:active {
        background: oklch(98% 0 0 / 0.05);
      }

      .song-title {
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        font-weight: 700;
      }

      .song-artist {
        font-size: clamp(0.6rem, 1.4vw, 0.7rem);
        color: var(--color-text-muted);
      }
    </style>
  </>;
}
