import { track } from 'ripple';
import type { LibrarySong } from '../types';
import { haptic, setQueue, addToQueue, getCoverArtUrl, playSong } from '../stores/now-playing';
import { library, searchLibrary, syncLibrary } from '../stores/library';
import { connection } from '../stores/connection';
import { navigate, navigateToArtist, navigateToAlbum } from '../stores/router';
import { IconButton } from './IconButton.tsrx';
import { SearchInput } from './SearchInput.tsrx';
import { Chip } from './Chip.tsrx';
import { TrackRow } from './TrackRow.tsrx';

const ROW_HEIGHT = 44;
const OVERSCAN = 10;

export function Library() {
  const _searchQuery = track('');
  const _scrollTop = track(0);
  const _containerHeight = track(640);
  let _debounceTimer: ReturnType<typeof setTimeout> | null = null;
  let _rafId = 0;

  const lib = library.state;
  const conn = connection;

  const songs = track(() => lib.data.value.songs);

  const _startIndex = track(() =>
    Math.max(0, Math.floor(_scrollTop.value / ROW_HEIGHT) - OVERSCAN)
  );

  const _endIndex = track(() =>
    Math.min(
      songs.value.length,
      Math.ceil((_scrollTop.value + _containerHeight.value) / ROW_HEIGHT) + OVERSCAN
    )
  );

  const _visibleSongs = track(() =>
    songs.value.slice(_startIndex.value, _endIndex.value)
  );

  const onSearchInput = (e: Event) => {
    const value = (e.target as HTMLInputElement).value;
    _searchQuery.value = value;
    if (_debounceTimer) clearTimeout(_debounceTimer);
    _debounceTimer = setTimeout(() => {
      searchLibrary(value).then((result) => {
        lib.data.value = result;
      }).catch(() => {});
    }, 200);
  };

  const onScroll = (e: Event) => {
    cancelAnimationFrame(_rafId);
    _rafId = requestAnimationFrame(() => {
      const el = e.target as HTMLElement;
      _scrollTop.value = el.scrollTop;
      _containerHeight.value = el.clientHeight;
    });
  };

  return <>
    <div class="library">
      if (conn.status.value !== 'connected') {
        <div class="library-state">
          <p>{'Connect to a server to browse your library.'}</p>
          <IconButton icon="" label="Go to Settings" variant="secondary" onClick={() => {
            haptic('light');
            navigate('settings');
          }} />
        </div>
      } else if (lib.syncing.value) {
        <div class="library-state">
          <span class="syncing-dot" />
          <p>{'Syncing library...'}</p>
        </div>
      } else if (lib.data.value.artists.length === 0 && lib.data.value.albums.length === 0 && lib.data.value.songs.length === 0) {
        <div class="library-state">
          <p>{'Library is empty.'}</p>
          <IconButton icon="" label="Sync" variant="primary" onClick={() => {
            haptic('medium');
            syncLibrary();
          }} />
        </div>
      } else {
        <div class="lib-toolbar">
          <SearchInput
            placeholder="Search artists, albums, songs..."
            value={_searchQuery.value}
            onInput={onSearchInput}
          />
        </div>

        if (lib.data.value.artists.length > 0) {
          <div class="chip-scroll">
            for (const a of lib.data.value.artists) {
              <button class="chip artist-chip" onClick={() => {
                haptic('selection');
                navigateToArtist(a.id, a.name);
              }}>
                {a.name}
              </button>
            }
          </div>
        }

        if (lib.data.value.albums.length > 0) {
          <div class="chip-scroll">
            for (const a of lib.data.value.albums) {
              <button class="chip album-chip" onClick={() => {
                haptic('selection');
                navigateToAlbum(a.id, a.name, a.artistId, a.artist);
              }}>
                {a.name}
              </button>
            }
          </div>
        }

        if (songs.value.length === 0) {
          <div class="library-state">
            <p>{'No results.'}</p>
          </div>
        } else {
          <div class="song-container" onScroll={onScroll}>
            <div style={{ height: `${_startIndex.value * ROW_HEIGHT}px` }} />
            for (const s of _visibleSongs.value; index i) {
              <TrackRow
                song={s}
                index={_startIndex.value + i}
                onPlay={async () => {
                  haptic('light');
                  setQueue(s);
                  const covUrl = await getCoverArtUrl(s.coverArt);
                  await playSong(s, covUrl);
                }}
                onAdd={(e: Event) => {
                  e.stopPropagation();
                  haptic('selection');
                  addToQueue(s);
                }}
              />
            }
            <div style={{ height: `${Math.max(0, (songs.value.length - _endIndex.value) * ROW_HEIGHT)}px` }} />
          </div>

          <div class="lib-footer">
            <span class="footer-glyph">{'▸'}</span>
            <span class="footer-count">{`${songs.value.length} songs`}</span>
            if (_searchQuery.value) {
              <span class="footer-query">{`matching "${_searchQuery.value}"`}</span>
            }
          </div>
        }
      }
    </div>

    <style>
      .library {
        display: flex;
        flex-direction: column;
        height: 100%;
      }

      .library-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 50vh;
        gap: 18px;
        text-align: center;
        color: var(--color-text-muted);
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        font-weight: 400;
        padding: var(--margin);
      }

      .syncing-dot {
        width: 10px;
        height: 10px;
        background: var(--color-primary);
        animation: lib-sync-pulse 0.8s step-end infinite;
      }

      @keyframes lib-sync-pulse {
        50% { opacity: 0; }
      }

      .lib-toolbar {
        padding: var(--gutter) var(--margin) 4px;
        flex-shrink: 0;
      }

      .chip-scroll {
        display: flex;
        gap: 8px;
        overflow-x: auto;
        padding: 4px var(--margin) 4px;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-x: contain;
        flex-shrink: 0;
      }

      .chip-scroll:last-of-type {
        padding-bottom: 8px;
      }

      .chip {
        flex-shrink: 0;
        padding: 6px 14px;
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-label);
        font-weight: 600;
        color: var(--color-text);
        background: var(--color-surface-lowest);
        white-space: nowrap;
        cursor: pointer;
        min-height: var(--tap-min);
        -webkit-tap-highlight-color: transparent;
        outline: none;
        transition: transform 0.05s ease, box-shadow 0.05s ease, background 0.15s ease;
      }

      .chip:active {
        transform: translate(var(--shadow-offset), var(--shadow-offset));
        box-shadow: none;
      }

      .artist-chip[data-active='true'] {
        background: var(--color-primary-container);
        color: var(--color-on-primary-container);
      }

      .song-container {
        flex: 1;
        min-height: 0;
        overflow-y: auto;
        overflow-x: hidden;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-y: contain;
      }

      .lib-footer {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px var(--margin);
        border-top: var(--border-width) solid var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.04em;
        color: var(--color-text-muted);
        flex-wrap: wrap;
        background: var(--color-surface);
      }

      .footer-glyph {
        color: var(--color-secondary);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
      }

      .footer-count {
        color: var(--color-text);
      }

      .footer-query {
        color: var(--color-text-muted);
        font-weight: 400;
      }
    </style>
  </>;
}
