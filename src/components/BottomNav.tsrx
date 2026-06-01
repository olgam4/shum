import type { Route } from '../types';
import { actions } from '../actions';
import { routeCtx, trackCtx } from '../context';

export function BottomNav() {
  const rt = routeCtx.get();
  const tk = trackCtx.get();

  return <>
    <nav class="bottom-nav">
      <button class="nav-tab" data-active={rt.current.value === 'home'} onClick={() => {
        actions.haptic('selection');
        rt.current.value = 'home';
      }}>
        <span class="nav-icon">{'⌘'}</span>
        <span class="nav-label">{'Home'}</span>
      </button>
      <button class="nav-tab" data-active={rt.current.value === 'library' || rt.current.value === 'artist' || rt.current.value === 'album'} onClick={() => {
        actions.haptic('selection');
        rt.current.value = 'library';
      }}>
        <span class="nav-icon">{'▤'}</span>
        <span class="nav-label">{'Library'}</span>
      </button>
      <button class="nav-tab" data-active={rt.current.value === 'settings'} onClick={() => {
        actions.haptic('selection');
        rt.current.value = 'settings';
      }}>
        <span class="nav-icon">{'⛭'}</span>
        <span class="nav-label">{'Settings'}</span>
      </button>
    </nav>

    <style>
      .bottom-nav {
        width: 100%;
        flex-shrink: 0;
        height: calc(var(--bottom-nav-height) + 4px + env(safe-area-inset-bottom, 0px) / 2);
        padding-top: 4px;
        padding-bottom: calc(env(safe-area-inset-bottom, 0px) / 2);
        padding-left: clamp(16px, 5vw, 48px);
        padding-right: clamp(16px, 5vw, 48px);
        display: flex;
        background: var(--color-surface-elevated);
        border-top: var(--border-width) solid var(--color-primary);
        z-index: 100;
      }

      .nav-tab {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 2px;
        min-height: var(--tap-min);
        border: none;
        background: transparent;
        color: var(--color-text-muted);
        cursor: pointer;
        transition: color 0.2s ease;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        padding: 0;
      }

      .nav-tab[data-active='true'] {
        color: var(--color-secondary);
      }

      .nav-icon {
        font-size: clamp(22px, 6vw, 28px);
        line-height: 1;
        text-align: center;
      }

      .nav-label {
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
        font-weight: 700;
        letter-spacing: 0.04em;
      }
    </style>
  </>;
}
