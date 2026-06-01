import { listen } from '@tauri-apps/api/event';
import { effect } from 'ripple';
import { initState } from './state';
import { actions } from './actions';
import type { AppState } from './types';
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

  effect(() => {
    actions.initAudio()
      .then(() => actions.getState().then((state) => s.applyState(state)).catch(() => {}))
      .catch(() => {});

    listen<AppState>('shum:state-changed', (e) => s.applyState(e.payload))
      .then((fn) => unlistenFns.push(fn)).catch(() => {});

    return () => unlistenFns.forEach((fn) => fn());
  });

  return <>
    <div class="app-root">
      <Header />
      <div class="page-content">
        switch (s.route.value) {
          case 'home':
            <Home track={s.track} playbackState={s.playbackState}
                  connection={s.connection} route={s.route}
                  syncSongCount={s.syncSongCount} syncAlbumCount={s.syncAlbumCount}
                  syncArtistCount={s.syncArtistCount} syncing={s.syncing} />
            break;
          case 'library':
            <Library library={s.library} connection={s.connection}
                     route={s.route} syncing={s.syncing} />
            break;
          case 'settings':
            <Settings connection={s.connection} lastSync={s.lastSync}
                      syncSongCount={s.syncSongCount} syncAlbumCount={s.syncAlbumCount}
                      syncArtistCount={s.syncArtistCount} syncing={s.syncing} />
            break;
          default:
            <Home track={s.track} playbackState={s.playbackState}
                  connection={s.connection} route={s.route}
                  syncSongCount={s.syncSongCount} syncAlbumCount={s.syncAlbumCount}
                  syncArtistCount={s.syncArtistCount} syncing={s.syncing} />
        }
      </div>
      if (s.track.value) {
        <NowPlayingWidget track={s.track} playbackState={s.playbackState}
                          artist={s.track.value?.artist ?? ''}
                          progressPercent={s.progressPercent}
                          playerOpen={s.playerOpen}
                          route={s.route} />
      }
      <BottomNav route={s.route} track={s.track} />
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
        --pr-paper: oklch(97% 0.01 90);
        --pr-paper-raised: oklch(93% 0.02 90);
        --pr-ink: oklch(15% 0.02 260);
        --pr-white: oklch(100% 0 0);

        --color-primary: var(--pr-yellow);
        --color-secondary: var(--pr-gentian);
        --color-tertiary: var(--pr-ruby);
        --color-surface: var(--pr-paper);
        --color-surface-elevated: var(--pr-paper-raised);
        --color-text: var(--pr-ink);
        --color-text-muted: oklch(15% 0.02 260 / 0.55);
        --border-width: 3px;
        --shadow-offset: 4px;
        --font-family: 'SF Mono', 'Fira Code', 'Courier New', monospace;
        --tap-min: 44px;
        --bottom-nav-height: 56px;
        --widget-height: 56px;
      }

      :global(body), :global(html), :global(#root) {
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
        overscroll-behavior: none;
        -webkit-tap-highlight-color: transparent;
      }

      .app-root {
        height: 100dvh; width: 100%;
        display: flex; flex-direction: column;
        overflow: hidden;
        position: relative;
        z-index: 0;
        padding-top: env(safe-area-inset-top, 0px);
        padding-left: env(safe-area-inset-left, 0px);
        padding-right: env(safe-area-inset-right, 0px);
      }

      .page-content {
        flex: 1;
        overflow-y: auto;
        overflow-x: hidden;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-y: contain;
      }
    </style>
  </>;
}
