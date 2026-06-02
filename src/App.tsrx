import { effect } from 'ripple';
import type { Route } from './types';
import { initStores, nowPlaying, connection, library, router } from './stores/init';
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
import { initAudio, haptic } from './stores/now-playing';
import { startupHydrate } from './stores/connection';
import { navigate, MAIN_TABS } from './stores/router';

export function App() {
  initStores();

  effect(() => {
    initAudio().catch(() => {});
    setupMediaSession();

    startupHydrate().then((state) => {
      connection.info.value = state.connectionStatus;
      connection.status.value = state.connectionStatus.connected ? 'connected' : 'disconnected';
      if (state.library) {
        library.state.data.value = { artists: state.library.artists, albums: state.library.albums, songs: state.library.songs };
        library.state.artistCount.value = state.library.artistCount;
        library.state.albumCount.value = state.library.albumCount;
        library.state.songCount.value = state.library.songCount;
        library.state.lastSync.value = state.library.lastSync;
      }
    }).catch(() => {});
  });

  let _touchStartX = 0;
  let _touchStartY = 0;

  const onTouchStart = (e: TouchEvent) => {
    _touchStartX = e.touches[0].clientX;
    _touchStartY = e.touches[0].clientY;
  };

  const onTouchEnd = (e: TouchEvent) => {
    const dx = (e as any).changedTouches[0].clientX - _touchStartX;
    const dy = (e as any).changedTouches[0].clientY - _touchStartY;
    if (Math.abs(dx) < 80 || Math.abs(dx) < Math.abs(dy) * 2) return;

    const rt = router.state;
    const target = (e as any).target as HTMLElement;
    let el: HTMLElement | null = target;
    while (el) {
      if (el.classList.contains('chip-scroll')) return;
      if (el.classList.contains('song-add')) return;
      if (el.classList.contains('track-add')) return;
      el = el.parentElement;
    }

    const cur = rt.current.value;
    const idx = MAIN_TABS.indexOf(cur as Route);
    if (idx === -1) {
      if (dx > 0) navigate('library');
      else if (dx < 0 && MAIN_TABS.indexOf('settings') > MAIN_TABS.indexOf('library')) return;
      return;
    }

    if (dx < 0 && idx < MAIN_TABS.length - 1) {
      haptic('selection');
      navigate(MAIN_TABS[idx + 1]);
    } else if (dx > 0 && idx > 0) {
      haptic('selection');
      navigate(MAIN_TABS[idx - 1]);
    }
  };

  const rt = router.state;
  const po = nowPlaying.playerOpen;
  const pc = nowPlaying.playerClosing;

  return <>
    <div class="app-root">
      <Header />
      <div class="page-content" data-direction={rt.direction.value}
        onTouchStart={onTouchStart}
        onTouchEnd={onTouchEnd}>
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
      if (nowPlaying.track.current.value) {
        <NowPlayingWidget />
      }
      <BottomNav />
    </div>
    if (po.open.value || pc.closing.value) {
      <Player />
    }

    <style>
      :global(:root) {
        --pr-primary: #6f5d00;
        --pr-primary-container: #ffda29;
        --pr-secondary: #3854c4;
        --pr-secondary-container: #718bfe;
        --pr-tertiary: #be0036;
        --pr-error: #ba1a1a;
        --pr-surface: #f9f9f9;
        --pr-surface-low: #f3f3f3;
        --pr-surface-lowest: #ffffff;
        --pr-surface-variant: #e2e2e2;
        --pr-surface-dim: #dadada;
        --pr-ink: #1b1b1b;
        --pr-muted: #4c4732;
        --pr-outline: #7e7760;

        --color-primary: var(--pr-primary);
        --color-primary-container: var(--pr-primary-container);
        --color-secondary: var(--pr-secondary);
        --color-secondary-container: var(--pr-secondary-container);
        --color-tertiary: var(--pr-tertiary);
        --color-error: var(--pr-error);
        --color-surface: var(--pr-surface);
        --color-surface-elevated: var(--pr-surface-low);
        --color-surface-lowest: var(--pr-surface-lowest);
        --color-surface-variant: var(--pr-surface-variant);
        --color-surface-dim: var(--pr-surface-dim);
        --color-text: var(--pr-ink);
        --color-text-muted: var(--pr-muted);
        --color-outline: var(--pr-outline);
        --color-on-primary: #ffffff;
        --color-on-primary-container: #715f00;
        --color-on-secondary: #ffffff;
        --color-on-tertiary: #ffffff;

        --border-width: 4px;
        --shadow-offset: 4px;
        --shadow-offset-lg: 8px;
        --margin: clamp(12px, 3vw, 24px);
        --gutter: clamp(8px, 2vw, 16px);
        --unit: 4px;
        --tap-min: 44px;
        --nav-height: 72px;
        --widget-height: 56px;
        --transition-duration: 0.25s;
        --transition-ease: cubic-bezier(0.22, 0.61, 0.36, 1);

        --font-family: 'Public Sans', -apple-system, system-ui, sans-serif;
        --fs-headline-xl: clamp(48px, 10vw, 80px);
        --fs-headline-lg: clamp(32px, 6vw, 48px);
        --fs-headline-md: clamp(24px, 4vw, 32px);
        --fs-body-bold: clamp(16px, 2.5vw, 18px);
        --fs-body-reg: clamp(14px, 2vw, 16px);
        --fs-label: clamp(13px, 1.5vw, 14px);
        --fs-metadata: clamp(11px, 1.2vw, 12px);
        --lh-headline-xl: 0.9;
        --lh-headline: 1;
        --lh-body: 1.33;
        --lh-body-reg: 1.375;
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

      :global(.brutal-border) {
        border: var(--border-width) solid var(--color-text);
        border-radius: 0;
      }

      :global(.brutal-shadow) {
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
      }

      :global(.brutal-shadow-lg) {
        box-shadow: var(--shadow-offset-lg) var(--shadow-offset-lg) 0 var(--color-text);
      }

      :global(.brutal-active):active {
        transform: translate(var(--shadow-offset), var(--shadow-offset));
        box-shadow: none;
      }

      :global(.brutal-active-lg):active {
        transform: translate(var(--shadow-offset-lg), var(--shadow-offset-lg));
        box-shadow: none;
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

      .page-content > * {
        animation-duration: var(--transition-duration);
        animation-timing-function: var(--transition-ease);
        animation-fill-mode: both;
      }

      .page-content[data-direction='forward'] > * {
        animation-name: page-enter-forward;
      }

      .page-content[data-direction='back'] > * {
        animation-name: page-enter-back;
      }

      @keyframes page-enter-forward {
        from { opacity: 0; transform: translateX(32px); }
        to { opacity: 1; transform: translateX(0); }
      }

      @keyframes page-enter-back {
        from { opacity: 0; transform: translateX(-32px); }
        to { opacity: 1; transform: translateX(0); }
      }
    </style>
  </>;
}
