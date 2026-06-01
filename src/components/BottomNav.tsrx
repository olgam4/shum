import type { Tracked } from 'ripple';
import type { Route, PlaybackState, TrackMeta } from '../types';
import { actions } from '../actions';

export function BottomNav(&{ route, track }: {
  route: Tracked<Route>;
  track: Tracked<TrackMeta | null>;
}) {
  return <>
    <nav class="bottom-nav">
      <button class="nav-tab" data-active={route === 'home'} onClick={() => {
        actions.haptic('selection');
        route.value = 'home';
      }}>
        <span class="nav-icon">{'🏠'}</span>
        <span class="nav-label">{'Home'}</span>
      </button>
      <button class="nav-tab" data-active={route === 'library'} onClick={() => {
        actions.haptic('selection');
        route.value = 'library';
      }}>
        <span class="nav-icon">{'📚'}</span>
        <span class="nav-label">{'Library'}</span>
      </button>
      <button class="nav-tab" data-active={route === 'settings'} onClick={() => {
        actions.haptic('selection');
        route.value = 'settings';
      }}>
        <span class="nav-icon">{'⚙'}</span>
        <span class="nav-label">{'Settings'}</span>
      </button>
    </nav>

    <style>
      .bottom-nav {
        position: fixed;
        bottom: 0; left: 0; right: 0;
        height: calc(var(--bottom-nav-height) + var(--safe-bottom));
        padding-bottom: var(--safe-bottom);
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
        color: var(--color-primary);
      }

      .nav-icon {
        font-size: clamp(1rem, 3vw, 1.25rem);
        line-height: 1;
      }

      .nav-label {
        font-size: clamp(0.55rem, 1.2vw, 0.65rem);
        font-weight: 700;
        letter-spacing: 0.06em;
      }
    </style>
  </>;
}
