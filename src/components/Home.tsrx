import type { Tracked } from 'ripple';
import type { ConnectionStatus, Route, PlaybackState, TrackMeta } from '../types';
import { actions } from '../actions';

export function Home(&{ track, playbackState, connection, route, syncSongCount, syncAlbumCount, syncArtistCount, syncing }: {
  track: Tracked<TrackMeta | null>;
  playbackState: Tracked<PlaybackState>;
  connection: Tracked<ConnectionStatus>;
  route: Tracked<Route>;
  syncSongCount: Tracked<number>;
  syncAlbumCount: Tracked<number>;
  syncArtistCount: Tracked<number>;
  syncing: Tracked<boolean>;
}) {
  return <>
    <div class="home">
      if (!track.value) {
        <div class="welcome-card">
          <h2 class="welcome-title">{'Welcome'}</h2>
          <p class="welcome-sub">{'Welcome to SHUM'}</p>
          if (syncing.value) {
            <div class="syncing-state">
              <span class="syncing-dot" />
              <span class="syncing-text">{'Syncing library...'}</span>
            </div>
          } else if (connection.value !== 'connected') {
            <div class="connect-prompt">
              <p class="prompt-text">{'No server connected.'}</p>
              <button class="prompt-btn" onClick={() => {
                actions.haptic('light');
                actions.navigate('settings');
              }}>
                {'Connect to Navidrome'}
              </button>
            </div>
          } else {
            <div class="stats">
              <div class="stat-item">
                <span class="stat-value">{syncSongCount.value}</span>
                <span class="stat-label">{'Songs'}</span>
              </div>
              <div class="stat-item">
                <span class="stat-value">{syncAlbumCount.value}</span>
                <span class="stat-label">{'Albums'}</span>
              </div>
              <div class="stat-item">
                <span class="stat-value">{syncArtistCount.value}</span>
                <span class="stat-label">{'Artists'}</span>
              </div>
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
        padding: clamp(16px, 4vw, 32px);
      }

      .welcome-card {
        border: var(--border-width) solid var(--color-primary);
        padding: clamp(24px, 6vw, 40px);
        box-shadow: 8px 8px 0px var(--color-secondary);
        background: var(--color-surface-elevated);
        text-align: center;
        max-width: 360px;
        width: 100%;
      }

      .welcome-title {
        font-size: clamp(1.25rem, 4vw, 2rem);
        font-weight: 900;
        color: var(--color-secondary);
        margin: 0 0 4px 0;
      }

      .welcome-sub {
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        color: var(--color-text-muted);
        margin: 0 0 20px 0;
      }

      .connect-prompt {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 12px;
      }

      .prompt-text {
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        color: var(--color-text-muted);
        margin: 0;
      }

      .prompt-btn {
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-secondary);
        background: var(--color-surface);
        color: var(--color-secondary);
        font-family: var(--font-family);
        font-weight: 800;
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        letter-spacing: 0.06em;
        padding: 10px 24px;
        cursor: pointer;
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--color-primary);
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .prompt-btn:active {
        transform: translate(2px, 2px);
        box-shadow: none;
      }

      .stats {
        display: flex;
        gap: clamp(16px, 4vw, 32px);
        justify-content: center;
        margin-top: 16px;
      }

      .stat-item {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 2px;
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
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        font-weight: 700;
        letter-spacing: 0.08em;
        color: var(--color-secondary);
      }

      .stat-value {
        font-size: clamp(1.5rem, 5vw, 2.5rem);
        font-weight: 900;
        color: var(--color-secondary);
      }

      .stat-label {
        font-size: clamp(0.55rem, 1.2vw, 0.65rem);
        font-weight: 700;
        letter-spacing: 0.08em;
        color: var(--color-text-muted);
      }

      .playing-indicator {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 12px 20px;
      }

      .playing-dot {
        width: 10px; height: 10px;
        background: var(--color-secondary);
        border-radius: 0;
        box-shadow: 0 0 8px oklch(52% 0.32 262 / 0.6);
        animation: home-dot-pulse 1.4s ease-in-out infinite;
      }

      @keyframes home-dot-pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.3; }
      }

      .playing-text {
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        font-weight: 700;
        letter-spacing: 0.08em;
        color: var(--color-text-muted);
      }
    </style>
  </>;
}
