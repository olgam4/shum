import { nowPlaying, haptic } from '../stores/now-playing';
import { connection } from '../stores/connection';
import { library } from '../stores/library';
import { navigate } from '../stores/router';
import { DataCell } from './DataCell.tsrx';
import { IconButton } from './IconButton.tsrx';

export function Home() {
  const conn = connection;
  const lib = library.state;
  const tk = nowPlaying.track;

  return <>
    <div class="home">
      if (!tk.current.value) {
        <div class="welcome-card">
          <h2 class="welcome-title">{'Welcome'}</h2>
          <p class="welcome-sub">{'Welcome to SHUM'}</p>
          if (lib.syncing.value) {
            <div class="syncing-state">
              <span class="syncing-dot" />
              <span class="syncing-text">{'Syncing library...'}</span>
            </div>
          } else if (conn.status.value !== 'connected') {
            <div class="connect-prompt">
              <p class="prompt-text">{'No server connected.'}</p>
              <IconButton icon="" label="Connect to Navidrome" variant="secondary" onClick={() => {
                haptic('light');
                navigate('settings');
              }} />
            </div>
          } else {
            <div class="stats-grid">
              <DataCell label="Songs" value={String(lib.songCount.value)} />
              <DataCell label="Albums" value={String(lib.albumCount.value)} />
              <DataCell label="Artists" value={String(lib.artistCount.value)} />
            </div>
          }
        </div>
      } else {
        <div class="playing-indicator">
          <span class="playing-dot" />
          <span class="playing-text">{'Now Playing'}</span>
        </div>
      }
    </div>

    <style>
      .home {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 100%;
        padding: var(--margin);
      }

      .welcome-card {
        border: var(--border-width) solid var(--color-text);
        padding: clamp(24px, 6vw, 40px);
        box-shadow: var(--shadow-offset-lg) var(--shadow-offset-lg) 0 var(--color-text);
        background: var(--color-surface-lowest);
        text-align: center;
        max-width: 360px;
        width: 100%;
      }

      .welcome-title {
        font-family: var(--font-family);
        font-size: var(--fs-headline-lg);
        font-weight: 900;
        letter-spacing: -0.04em;
        line-height: var(--lh-headline);
        color: var(--color-text);
        margin: 0 0 4px 0;
      }

      .welcome-sub {
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        font-weight: 400;
        color: var(--color-text-muted);
        margin: 0 0 20px 0;
      }

      .connect-prompt {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 14px;
      }

      .prompt-text {
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        font-weight: 400;
        color: var(--color-text-muted);
        margin: 0;
      }

      .stats-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: var(--gutter);
        margin-top: 20px;
      }

      .syncing-state {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 10px;
        margin-top: 16px;
      }

      .syncing-dot {
        width: 10px; height: 10px;
        background: var(--color-primary);
        animation: home-sync-pulse 0.8s step-end infinite;
      }

      @keyframes home-sync-pulse {
        50% { opacity: 0; }
      }

      .syncing-text {
        font-family: var(--font-family);
        font-size: var(--fs-label);
        font-weight: 600;
        letter-spacing: 0.06em;
        color: var(--color-secondary);
      }

      .playing-indicator {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 16px 24px;
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-lowest);
      }

      .playing-dot {
        width: 12px; height: 12px;
        background: var(--color-secondary);
        box-shadow: 0 0 10px var(--color-secondary-container);
        animation: home-dot-pulse 1.4s ease-in-out infinite;
      }

      @keyframes home-dot-pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.3; }
      }

      .playing-text {
        font-family: var(--font-family);
        font-size: var(--fs-label);
        font-weight: 600;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
      }
    </style>
  </>;
}
