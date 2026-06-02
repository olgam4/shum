import type { Route } from '../types';
import { haptic } from '../stores/now-playing';
import { router, navigate } from '../stores/router';

export function BottomNav() {
  const rt = router.state;

  return <>
    <nav class="bottom-nav">
      <button class="nav-tab" data-active={rt.current.value === 'home'} onClick={() => {
        haptic('selection');
        navigate('home');
      }}>
        <span class="nav-icon">{'⌘'}</span>
        <span class="nav-label">{'Home'}</span>
      </button>
      <button class="nav-tab" data-active={rt.current.value === 'library' || rt.current.value === 'artist' || rt.current.value === 'album'} onClick={() => {
        haptic('selection');
        navigate('library');
      }}>
        <span class="nav-icon">{'▤'}</span>
        <span class="nav-label">{'Library'}</span>
      </button>
      <button class="nav-tab" data-active={rt.current.value === 'settings'} onClick={() => {
        haptic('selection');
        navigate('settings');
      }}>
        <span class="nav-icon">{'⛭'}</span>
        <span class="nav-label">{'Settings'}</span>
      </button>
    </nav>

    <style>
      .bottom-nav {
        width: 100%;
        flex-shrink: 0;
        height: calc(var(--nav-height) + env(safe-area-inset-bottom, 0px) / 2);
        padding-bottom: calc(env(safe-area-inset-bottom, 0px) / 2);
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        background: var(--color-surface);
        border-top: var(--border-width) solid var(--color-text);
        z-index: 100;
      }

      .nav-tab {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 2px;
        border: none;
        border-right: 2px solid var(--color-text);
        background: transparent;
        color: var(--color-text-muted);
        cursor: pointer;
        transition: background 0.15s ease, color 0.15s ease;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        padding: 0;
        min-height: var(--tap-min);
      }

      .nav-tab:last-child {
        border-right: none;
      }

      .nav-tab[data-active='true'] {
        background: var(--color-primary);
        color: var(--color-on-primary);
      }

      .nav-tab:hover:not([data-active='true']) {
        background: var(--color-tertiary);
        color: var(--color-on-tertiary);
      }

      .nav-tab:active:not([data-active='true']) {
        background: var(--color-secondary-container);
      }

      .nav-icon {
        font-size: clamp(22px, 5vw, 28px);
        line-height: 1;
      }

      .nav-label {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.04em;
      }
    </style>
  </>;
}
