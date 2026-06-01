import type { Tracked } from 'ripple';
import { track } from 'ripple';
import type { ConnectionStatus, Route, SearchResult, LibrarySong, LibraryAlbum, LibraryArtist } from '../types';
import { actions } from '../actions';
import { formatTime } from '../state';

const ROW_HEIGHT = 44;
const OVERSCAN = 10;

export function Library(&{ library, connection, route, syncing }: {
  library: Tracked<SearchResult>;
  connection: Tracked<ConnectionStatus>;
  route: Tracked<Route>;
  syncing: Tracked<boolean>;
}) {
  const _searchQuery = track('');
  const _libraryFilter = track<{ type: 'artist' | 'album'; id: string; name: string } | null>(null);
  const _scrollTop = track(0);
  const _containerHeight = track(640);
  let _debounceTimer: ReturnType<typeof setTimeout> | null = null;
  let _rafId = 0;

  const _filteredSongs = track(() => {
    const filter = _libraryFilter.value;
    const songs = library.value.songs;
    if (!filter) return songs;
    if (filter.type === 'artist') return songs.filter(s => s.artistId === filter.id);
    return songs.filter(s => s.albumId === filter.id);
  });

  const _startIndex = track(() =>
    Math.max(0, Math.floor(_scrollTop.value / ROW_HEIGHT) - OVERSCAN)
  );

  const _endIndex = track(() =>
    Math.min(
      _filteredSongs.value.length,
      Math.ceil((_scrollTop.value + _containerHeight.value) / ROW_HEIGHT) + OVERSCAN
    )
  );

  const _visibleSongs = track(() =>
    _filteredSongs.value.slice(_startIndex.value, _endIndex.value)
  );

  const onSearchInput = (e: Event) => {
    const value = (e.target as HTMLInputElement).value;
    _searchQuery.value = value;
    if (_debounceTimer) clearTimeout(_debounceTimer);
    _debounceTimer = setTimeout(() => {
      actions.searchLibrary(value).catch(() => {});
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

  const handleChipClick = (type: 'artist' | 'album', id: string, name: string) => {
    actions.haptic('selection');
    const filter = _libraryFilter.value;
    if (filter?.type === type && filter?.id === id) {
      _libraryFilter.value = null;
    } else {
      _libraryFilter.value = { type, id, name };
    }
  };

  return <>
    <div class="library">
      if (connection.value !== 'connected') {
        <div class="library-state">
          <p>{'Connect to a server to browse your library.'}</p>
          <button class="lib-btn" onClick={() => {
            actions.haptic('light');
            actions.navigate('settings');
          }}>
            {'Go to Settings'}
          </button>
        </div>
      } else if (syncing.value) {
        <div class="library-state">
          <span class="syncing-dot" />
          <p>{'Syncing library...'}</p>
        </div>
      } else if (library.value.artists.length === 0 && library.value.albums.length === 0 && library.value.songs.length === 0) {
        <div class="library-state">
          <p>{'Library is empty.'}</p>
          <button class="lib-btn" onClick={() => {
            actions.haptic('medium');
            actions.syncLibrary();
          }}>
            {'SYNC'}
          </button>
        </div>
      } else {
        <div class="lib-toolbar">
          <input
            class="search-input"
            type="text"
            placeholder="Search artists, albums, songs..."
            value={_searchQuery.value}
            onInput={onSearchInput}
          />
        </div>

        if (library.value.artists.length > 0) {
          <div class="chip-scroll">
            for (const a of library.value.artists) {
              <button
                class="chip artist-chip"
                data-active={_libraryFilter.value?.type === 'artist' && _libraryFilter.value?.id === a.id}
                onClick={() => handleChipClick('artist', a.id, a.name)}
              >
                {a.name}
              </button>
            }
          </div>
        }

        if (library.value.albums.length > 0) {
          <div class="chip-scroll">
            for (const a of library.value.albums) {
              <button
                class="chip album-chip"
                data-active={_libraryFilter.value?.type === 'album' && _libraryFilter.value?.id === a.id}
                onClick={() => handleChipClick('album', a.id, a.name)}
              >
                {a.name}
              </button>
            }
          </div>
        }

        if (_libraryFilter.value) {
          <div class="active-filter">
            <span class="filter-glyph">{_libraryFilter.value.type === 'artist' ? '⌖' : '◉'}</span>
            <span class="filter-name">{_libraryFilter.value.name}</span>
            <button class="filter-clear" onClick={() => {
              actions.haptic('light');
              _libraryFilter.value = null;
            }}>{'✕'}</button>
          </div>
        }

        if (_filteredSongs.value.length === 0) {
          <div class="library-state">
            <p>{_libraryFilter.value ? `No songs for ${_libraryFilter.value.name}.` : 'No results.'}</p>
            if (_libraryFilter.value) {
              <button class="lib-btn" onClick={() => {
                actions.haptic('light');
                _libraryFilter.value = null;
              }}>
                {'Clear Filter'}
              </button>
            }
          </div>
        } else {
          <div class="song-container" onScroll={onScroll}>
            <div style={{ height: `${_startIndex.value * ROW_HEIGHT}px` }} />
            for (const s of _visibleSongs.value) {
              <button class="song-row" onClick={async () => {
                actions.haptic('light');
                actions.getCoverArtUrl(s.coverArt)
                  .then((covUrl) => actions.requestPlaySong(s, covUrl))
                  .catch(() => actions.haptic('error'));
              }}>
                <span class="song-track">{`${String(s.track).padStart(2, '0')}`}</span>
                <span class="song-title">{s.title}</span>
                <span class="song-artist">{s.artist}</span>
                <span class="song-album">{s.album}</span>
                <span class="song-duration">{formatTime(s.duration)}</span>
              </button>
            }
            <div style={{ height: `${Math.max(0, (_filteredSongs.value.length - _endIndex.value) * ROW_HEIGHT)}px` }} />
          </div>

          <div class="lib-footer">
            <span class="footer-glyph">{'▸'}</span>
            <span class="footer-count">{`${_filteredSongs.value.length} songs`}</span>
            if (_searchQuery.value) {
              <span class="footer-query">{`matching "${_searchQuery.value}"`}</span>
            }
            if (_libraryFilter.value) {
              <span class="footer-filter">{`· ${_libraryFilter.value.name}`}</span>
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
        gap: 16px;
        text-align: center;
        color: var(--color-text-muted);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        padding: clamp(12px, 3vw, 20px);
      }

      .lib-btn {
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-primary);
        background: var(--color-surface);
        color: var(--color-secondary);
        font-family: var(--font-family);
        font-weight: 800;
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        letter-spacing: 0.06em;
        padding: 8px 20px;
        cursor: pointer;
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--color-secondary);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .lib-btn:active {
        transform: translate(2px, 2px);
        box-shadow: none;
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
        padding: 8px clamp(8px, 2vw, 14px) 4px;
        flex-shrink: 0;
      }

      .search-input {
        width: 100%;
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-primary);
        box-shadow: 3px 3px 0px var(--color-secondary);
        background: var(--color-surface-elevated);
        color: var(--color-text);
        font-family: var(--font-family);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        font-weight: 700;
        padding: 6px 12px;
        outline: none;
        -webkit-appearance: none;
        box-sizing: border-box;
      }

      .search-input:focus {
        border-color: var(--color-secondary);
        box-shadow: 3px 3px 0px var(--color-primary);
      }

      .search-input::placeholder {
        color: var(--color-text-muted);
        font-weight: 400;
        font-size: clamp(0.65rem, 1.6vw, 0.75rem);
      }

      .chip-scroll {
        display: flex;
        gap: 6px;
        overflow-x: auto;
        padding: 4px clamp(8px, 2vw, 14px) 2px;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-x: contain;
        flex-shrink: 0;
      }

      .chip-scroll:last-of-type {
        padding-bottom: 4px;
      }

      .chip {
        flex-shrink: 0;
        padding: 4px 12px;
        border: 2px solid var(--color-secondary);
        font-family: var(--font-family);
        font-size: clamp(0.55rem, 1.3vw, 0.65rem);
        font-weight: 700;
        color: var(--color-text);
        background: var(--color-surface-elevated);
        white-space: nowrap;
        cursor: pointer;
        min-height: 32px;
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .chip:active {
        transform: translate(1px, 1px);
      }

      .chip[data-active='true'] {
        background: var(--color-secondary);
        color: var(--color-surface);
        border-color: var(--color-secondary);
        box-shadow: 2px 2px 0px var(--color-primary);
      }

      .artist-chip[data-active='true'] {
        background: var(--color-primary);
        color: var(--color-ink, var(--pr-ink));
        border-color: var(--color-primary);
      }

      .active-filter {
        display: flex;
        align-items: center;
        gap: 8px;
        margin: 6px clamp(8px, 2vw, 14px) 2px;
        padding: 6px 12px;
        border: var(--border-width) solid var(--color-tertiary);
        box-shadow: 3px 3px 0px var(--color-primary);
        background: var(--color-surface-elevated);
        flex-shrink: 0;
      }

      .filter-glyph {
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        color: var(--color-tertiary);
        line-height: 1;
      }

      .filter-name {
        flex: 1;
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
        font-weight: 700;
        color: var(--color-text);
        letter-spacing: 0.04em;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .filter-clear {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 28px;
        height: 28px;
        border: 2px solid var(--color-tertiary);
        background: transparent;
        color: var(--color-tertiary);
        font-family: var(--font-family);
        font-size: 0.7rem;
        font-weight: 800;
        cursor: pointer;
        padding: 0;
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .filter-clear:active {
        background: var(--color-tertiary);
        color: var(--color-surface);
      }

      .song-container {
        flex: 1;
        min-height: 0;
        overflow-y: auto;
        overflow-x: hidden;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-y: contain;
      }

      .song-row {
        display: grid;
        grid-template-columns: 26px 2fr 1.3fr 1fr auto;
        gap: 4px;
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

      .song-row:nth-child(even) {
        background: oklch(15% 0.02 260 / 0.015);
      }

      .song-row:active {
        background: oklch(15% 0.02 260 / 0.06);
      }

      .song-track {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        font-weight: 400;
        color: var(--color-text-muted);
        text-align: right;
        font-variant-numeric: tabular-nums;
      }

      .song-title {
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
        font-weight: 700;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .song-artist {
        font-size: clamp(0.55rem, 1.3vw, 0.65rem);
        color: var(--color-text-muted);
        font-weight: 400;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .song-album {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        color: var(--color-text-muted);
        font-weight: 400;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        display: none;
      }

      @media (min-width: 400px) {
        .song-album {
          display: block;
        }
      }

      .song-duration {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        font-weight: 400;
        color: var(--color-text-muted);
        text-align: right;
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
      }

      .lib-footer {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 8px clamp(8px, 2vw, 14px);
        padding-bottom: 8px;
        border-top: 2px solid oklch(15% 0.02 260 / 0.1);
        font-size: clamp(0.55rem, 1.3vw, 0.65rem);
        color: var(--color-text-muted);
        font-weight: 700;
        letter-spacing: 0.04em;
        flex-wrap: wrap;
      }

      .footer-glyph {
        color: var(--color-secondary);
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
      }

      .footer-count {
        color: var(--color-text);
      }

      .footer-query {
        color: var(--color-text-muted);
        font-weight: 400;
      }

      .footer-filter {
        color: var(--color-tertiary);
      }
    </style>
  </>;
}
