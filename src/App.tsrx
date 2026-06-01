import { effect } from 'ripple';
import { initContexts, ctx, routeCtx, playerOpenCtx, trackCtx, connectionCtx, libraryCtx } from './context';
import { actions } from './actions';
import { computed } from './state';
import { setupMediaSession } from './media-session';
import { Header } from './components/Header.tsrx';
import { BottomNav } from './components/BottomNav.tsrx';
import { Home } from './components/Home.tsrx';
import { Library } from './components/Library.tsrx';
import { Settings } from './components/Settings.tsrx';
import { NowPlayingWidget } from './components/NowPlayingWidget.tsrx';
import { Player } from './components/Player.tsrx';
import { ArtistPage } from './components/ArtistPage.tsrx';
import { AlbumPage } from './components/AlbumPage.tsrx';

export function App() {
  initContexts();

  effect(() => {
    actions.initAudio().catch(() => {});
    setupMediaSession();

    actions.startupHydrate().then((state) => {
      ctx.connection.info.value = state.connectionStatus;
      ctx.connection.status.value = state.connectionStatus.connected ? 'connected' : 'disconnected';
      if (state.library) {
        ctx.library.data.value = { artists: state.library.artists, albums: state.library.albums, songs: state.library.songs };
        ctx.library.artistCount.value = state.library.artistCount;
        ctx.library.albumCount.value = state.library.albumCount;
        ctx.library.songCount.value = state.library.songCount;
        ctx.library.lastSync.value = state.library.lastSync;
      }
    }).catch(() => {});
  });

  const rt = routeCtx.get();
  const po = playerOpenCtx.get();
  const tk = trackCtx.get();
  const pb = computed;

  return <>
    <div class="app-root">
      <Header />
      <div class="page-content">
        switch (rt.current.value) {
          case 'home':
            <Home />
            break;
          case 'library':
            <Library />
            break;
          case 'settings':
            <Settings />
            break;
          case 'artist':
            <ArtistPage />
            break;
          case 'album':
            <AlbumPage />
            break;
          default:
            <Home />
        }
      </div>
      if (tk.current.value) {
        <NowPlayingWidget />
      }
      <BottomNav />
    </div>
    if (po.open.value) {
      <Player />
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
        --bottom-nav-height: 40px;
        --widget-height: 56px;
      }

      :global(*), :global(*::before), :global(*::after) {
        box-sizing: border-box;
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
