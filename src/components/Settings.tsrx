import { track, effect } from 'ripple';
import type { Tracked } from 'ripple';
import type { ConnectionStatus } from '../types';
import { actions } from '../actions';

export function Settings(&{ connection, lastSync, syncSongCount, syncAlbumCount, syncArtistCount }: {
  connection: Tracked<ConnectionStatus>;
  lastSync: Tracked<string | null>;
  syncSongCount: Tracked<number>;
  syncAlbumCount: Tracked<number>;
  syncArtistCount: Tracked<number>;
}) {
  const serverUrl  = track('');
  const username   = track('');
  const password   = track('');
  const connecting = track(false);
  const errorMsg   = track<string | null>(null);

  return <>
    <div class="settings">
      <div class="section">
        <h3 class="section-title">{'Server Connection'}</h3>

        <div class="input-group">
          <label class="input-label">{'Server URL'}</label>
          <input class="input-field" type="url" placeholder="https://navidrome.example.com"
                 value={serverUrl.value} onInput={(e) => serverUrl.value = e.target.value} />
        </div>

        <div class="input-group">
          <label class="input-label">{'Username'}</label>
          <input class="input-field" type="text" placeholder="admin"
                 value={username.value} onInput={(e) => username.value = e.target.value} />
        </div>

        <div class="input-group">
          <label class="input-label">{'Password'}</label>
          <input class="input-field" type="password" placeholder="••••••••"
                 value={password.value} onInput={(e) => password.value = e.target.value} />
        </div>

        if (connection !== 'connected') {
          <button class="connect-btn" disabled={connecting} onClick={() => {
            actions.haptic('medium');
            connecting.value = true;
            errorMsg.value = null;
            actions.connectServer(serverUrl.value, username.value, password.value)
              .then(() => { connecting.value = false; })
              .catch((e) => { connecting.value = false; errorMsg.value = String(e); });
          }}>
            {connecting ? 'Connecting...' : 'СВЯЗАТЬСЯ'}
          </button>
        } else {
          <button class="disconnect-btn" onClick={() => {
            actions.haptic('heavy');
            actions.disconnect();
          }}>
            {'Отключить'}
          </button>
        }

        <div class="connection-status">
          switch (connection) {
            case 'connected':
              <span class="status-dot" data-state="connected" />
              <span class="status-text connected">{'Connected'}</span>
            case 'connecting':
              <span class="status-dot" data-state="connecting" />
              <span class="status-text connecting">{'Connecting...'}</span>
            case 'disconnected':
              <span class="status-dot" data-state="disconnected" />
              <span class="status-text disconnected">{'Disconnected'}</span>
          }
          if (errorMsg) {
            <span class="status-error">{errorMsg}</span>
          }
        </div>
      </div>

      if (connection === 'connected') {
        <div class="section">
          <h3 class="section-title">{'Sync'}</h3>
          <button class="sync-btn" onClick={() => {
            actions.haptic('medium');
            actions.syncLibrary().catch(() => {});
          }}>
            {'СИНХРОНИЗАЦИЯ'}
          </button>
          <div class="sync-stats">
            <div class="sync-row">
              <span class="sync-label">{'Songs'}</span>
              <span class="sync-value">{syncSongCount}</span>
            </div>
            <div class="sync-row">
              <span class="sync-label">{'Albums'}</span>
              <span class="sync-value">{syncAlbumCount}</span>
            </div>
            <div class="sync-row">
              <span class="sync-label">{'Artists'}</span>
              <span class="sync-value">{syncArtistCount}</span>
            </div>
          </div>
        </div>
      }

      <div class="section">
        <h3 class="section-title">{'App'}</h3>
        <p class="app-version">{'SHUM v0.1.0'}</p>
        <p class="app-credits">{'Built with Tauri + Ripple-TS + Rust'}</p>
      </div>
    </div>

    <style>
      .settings {
        padding: clamp(12px, 3vw, 20px);
        display: flex;
        flex-direction: column;
        gap: clamp(16px, 4vw, 24px);
      }

      .section {
        border: var(--border-width) solid var(--color-secondary);
        padding: clamp(14px, 3vw, 20px);
        background: var(--color-surface-elevated);
      }

      .section-title {
        font-size: clamp(0.7rem, 1.8vw, 0.8rem);
        font-weight: 800;
        letter-spacing: 0.08em;
        color: var(--color-primary);
        margin: 0 0 12px 0;
      }

      .input-group {
        display: flex;
        flex-direction: column;
        gap: 4px;
        margin-bottom: 12px;
      }

      .input-label {
        font-size: clamp(0.6rem, 1.4vw, 0.7rem);
        font-weight: 700;
        color: var(--color-text-muted);
        letter-spacing: 0.04em;
      }

      .input-field {
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-primary);
        background: var(--color-surface);
        color: var(--color-text);
        font-family: var(--font-family);
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        padding: 8px 12px;
        outline: none;
        -webkit-appearance: none;
      }

      .input-field:focus {
        border-color: var(--color-secondary);
      }

      .input-field::placeholder {
        color: var(--color-text-muted);
      }

      .connect-btn, .disconnect-btn, .sync-btn {
        width: 100%;
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-primary);
        background: var(--color-surface);
        color: var(--color-primary);
        font-family: var(--font-family);
        font-weight: 800;
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        letter-spacing: 0.06em;
        padding: 10px 24px;
        cursor: pointer;
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--color-secondary);
        -webkit-tap-highlight-color: transparent;
        outline: none;
        margin-top: 4px;
      }

      .connect-btn:active, .disconnect-btn:active, .sync-btn:active {
        transform: translate(2px, 2px);
        box-shadow: none;
      }

      .connect-btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      .disconnect-btn {
        border-color: var(--color-tertiary);
        color: var(--color-tertiary);
      }

      .connection-status {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-top: 12px;
        flex-wrap: wrap;
      }

      .status-dot {
        width: 8px; height: 8px;
        flex-shrink: 0;
      }

      .status-dot[data-state='connected'] {
        background: var(--color-secondary);
        box-shadow: 0 0 6px oklch(52% 0.32 262 / 0.5);
      }

      .status-dot[data-state='connecting'] {
        background: var(--color-primary);
        animation: status-blink 0.6s step-end infinite;
      }

      .status-dot[data-state='disconnected'] {
        background: var(--color-text-muted);
      }

      @keyframes status-blink {
        50% { opacity: 0; }
      }

      .status-text {
        font-size: clamp(0.6rem, 1.4vw, 0.7rem);
        font-weight: 700;
        letter-spacing: 0.06em;
      }

      .status-text.connected { color: var(--color-secondary); }
      .status-text.connecting { color: var(--color-primary); }
      .status-text.disconnected { color: var(--color-text-muted); }

      .status-error {
        width: 100%;
        font-size: clamp(0.55rem, 1.2vw, 0.65rem);
        color: var(--color-tertiary);
        margin-top: 4px;
        word-break: break-all;
      }

      .sync-stats {
        margin-top: 12px;
        display: flex;
        flex-direction: column;
        gap: 6px;
      }

      .sync-row {
        display: flex;
        justify-content: space-between;
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
      }

      .sync-label { color: var(--color-text-muted); }
      .sync-value { color: var(--color-secondary); font-weight: 800; }

      .app-version {
        font-size: clamp(0.65rem, 1.5vw, 0.75rem);
        font-weight: 800;
        color: var(--color-primary);
        margin: 0;
      }

      .app-credits {
        font-size: clamp(0.55rem, 1.2vw, 0.65rem);
        color: var(--color-text-muted);
        margin: 2px 0 0 0;
      }
    </style>
  </>;
}
