import { listen } from '@tauri-apps/api/event';
import { effect } from 'ripple';
import { initState } from './state';
import type { AudioState } from './types';
import { Header } from './components/Header.tsrx';
import { EmptyState } from './components/EmptyState.tsrx';
import { NowPlaying } from './components/NowPlaying.tsrx';
import { ProgressBar } from './components/ProgressBar.tsrx';
import { TransportControls } from './components/TransportControls.tsrx';
import { VolumeControl } from './components/VolumeControl.tsrx';
import { StatusBar } from './components/StatusBar.tsrx';

export function App() {
  const s = initState();
  const unlistenFns: (() => void)[] = [];

  listen<AudioState>('shum:state-changed', (e) => s.applyState(e.payload))
    .then((fn) => unlistenFns.push(fn));
  listen<AudioState>('shum:position-tick', (e) => {
    s.progress.value = e.payload.positionSecs;
  }).then((fn) => unlistenFns.push(fn));

  effect(() => () => unlistenFns.forEach((fn) => fn()));

  return <>
    <div class="wall-of-sound">
      <Header />
      if (s.track.value) {
        <div class="now-playing-panel">
          <NowPlaying track={s.track} playbackState={s.playbackState} />
          <ProgressBar
            progressPercent={s.progressPercent}
            progress={s.progress}
            duration={s.duration}
          />
          <TransportControls playbackState={s.playbackState} track={s.track} />
          <VolumeControl volumePercent={s.volumePercent} />
          <StatusBar playbackState={s.playbackState} />
        </div>
      } else {
        <EmptyState />
      }
    </div>

    <style>
      :global(:root) {
        --shum-yellow: oklch(89% 0.21 100);
        --shum-gentian: oklch(52% 0.32 262);
        --shum-ruby: oklch(53% 0.28 12);
        --shum-ink: oklch(12% 0.02 260);
        --shum-ink-raised: oklch(16% 0.02 260);
        --shum-white: oklch(98% 0 0);
        --shum-border: 3px;
        --shum-shadow: 4px;
        --shum-font: 'SF Mono', 'Fira Code', 'Courier New', monospace;
        --shum-color-surface: var(--shum-ink);
        --shum-color-surface-raised: var(--shum-ink-raised);
        --shum-color-text: var(--shum-white);
        --shum-color-text-muted: oklch(98% 0 0 / 0.45);
        --shum-color-brand: var(--shum-yellow);
        --shum-color-accent: var(--shum-gentian);
        --shum-color-danger: var(--shum-ruby);
      }

      :global(body),
      :global(html),
      :global(#root) {
        margin: 0;
        padding: 0;
        height: 100%;
        width: 100%;
        overflow: hidden;
        background: var(--shum-color-surface);
        color: var(--shum-color-text);
        font-family: var(--shum-font);
        -webkit-font-smoothing: antialiased;
        -webkit-user-select: none;
        user-select: none;
        touch-action: manipulation;
      }

      .wall-of-sound {
        height: 100%;
        width: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: clamp(16px, 4vw, 40px);
        gap: clamp(20px, 5vh, 48px);
      }

      .now-playing-panel {
        width: 100%;
        max-width: 420px;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: clamp(16px, 3vh, 32px);
        border: var(--shum-border) solid var(--shum-color-brand);
        padding: clamp(20px, 5vw, 36px);
        box-shadow: 8px 8px 0px var(--shum-color-accent);
        background: var(--shum-color-surface-raised);
      }
    </style>
  </>;
}
