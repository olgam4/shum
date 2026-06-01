import { listen } from '@tauri-apps/api/event';
import { effect } from 'ripple';
import { initState } from './state';
import type { AudioState, ConnectionInfo, LibrarySnapshot, SearchResult, CacheProgress } from './types';
import { Header } from './components/Header.tsrx';
import { BottomNav } from './components/BottomNav.tsrx';
import { Home } from './components/Home.tsrx';
import { Library } from './components/Library.tsrx';
import { Settings } from './components/Settings.tsrx';
import { NowPlayingWidget } from './components/NowPlayingWidget.tsrx';
import { Player } from './components/Player.tsrx';

export function App() {
  const s = initState();
  const unlistenFns: (() => void)[] = [];

  listen<AudioState>('shum:state-changed', (e) => s.applyAudioState(e.payload))
    .then((fn) => unlistenFns.push(fn));
  listen<AudioState>('shum:position-tick', (e) => {
    s.progress.value = e.payload.positionSecs;
  }).then((fn) => unlistenFns.push(fn));
  listen<ConnectionInfo>('shum:connection-changed', (e) => s.applyConnection(e.payload))
    .then((fn) => unlistenFns.push(fn));
  listen<LibrarySnapshot>('shum:library-synced', (e) => s.applyLibrarySnapshot(e.payload))
    .then((fn) => unlistenFns.push(fn));
  listen<SearchResult>('shum:search-results', (e) => s.applySearchResults(e.payload))
    .then((fn) => unlistenFns.push(fn));

  effect(() => () => unlistenFns.forEach((fn) => fn()));

  return <>
    <div class="app-root">
      <Header />
      <div class="page-content">
        switch (s.route.value) {
          case 'home':
            <Home track={s.track} playbackState={s.playbackState}
                  connection={s.connection} route={s.route}
                  syncSongCount={s.syncSongCount} syncAlbumCount={s.syncAlbumCount}
                  syncArtistCount={s.syncArtistCount} />
          case 'library':
            <Library library={s.library} connection={s.connection}
                     route={s.route} />
          case 'settings':
            <Settings connection={s.connection} lastSync={s.lastSync}
                      syncSongCount={s.syncSongCount} syncAlbumCount={s.syncAlbumCount}
                      syncArtistCount={s.syncArtistCount} />
        }
      </div>
      if (s.track.value) {
        <NowPlayingWidget track={s.track} playbackState={s.playbackState}
                          artist={s.track.value?.artist ?? ''}
                          progressPercent={s.progressPercent}
                          playerOpen={s.playerOpen}
                          route={s.route} />
      }
      <BottomNav route={s.route} playbackState={s.playbackState}
                 track={s.track} />
    </div>
    if (s.playerOpen.value) {
      <Player track={s.track} playbackState={s.playbackState}
              progress={s.progress} duration={s.duration}
              progressPercent={s.progressPercent} volume={s.volume}
              volumePercent={s.volumePercent} playerOpen={s.playerOpen} />
    }

    <style>
      :global(:root) {
        --pr-yellow: oklch(89% 0.21 100);
        --pr-gentian: oklch(52% 0.32 262);
        --pr-ruby: oklch(53% 0.28 12);
        --pr-ink: oklch(12% 0.02 260);
        --pr-ink-raised: oklch(16% 0.02 260);
        --pr-white: oklch(98% 0 0);

        --color-primary: var(--pr-yellow);
        --color-secondary: var(--pr-gentian);
        --color-tertiary: var(--pr-ruby);
        --color-surface: var(--pr-ink);
        --color-surface-elevated: var(--pr-ink-raised);
        --color-text: var(--pr-white);
        --color-text-muted: oklch(98% 0 0 / 0.45);
        --border-width: 3px;
        --shadow-offset: 4px;
        --font-family: 'SF Mono', 'Fira Code', 'Courier New', monospace;
        --tap-min: 44px;
        --bottom-nav-height: 56px;
        --widget-height: 56px;
        --safe-bottom: env(safe-area-inset-bottom, 0px);
      }

      :global(body),
      :global(html),
      :global(#root) {
        margin: 0; padding: 0;
        height: 100dvh; width: 100%;
        overflow: hidden;
        background: var(--color-surface);
        color: var(--color-text);
        font-family: var(--font-family);
        -webkit-font-smoothing: antialiased;
        -webkit-user-select: none;
        user-select: none;
        touch-action: manipulation;
      }

      .app-root {
        height: 100dvh; width: 100%;
        display: flex; flex-direction: column;
        position: relative;
      }

      .page-content {
        flex: 1;
        overflow-y: auto;
        overflow-x: hidden;
        padding-bottom: calc(var(--bottom-nav-height) + var(--safe-bottom));
        -webkit-overflow-scrolling: touch;
      }
    </style>
  </>;
}
