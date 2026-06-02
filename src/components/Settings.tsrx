import { track } from 'ripple';
import { haptic } from '../stores/now-playing';
import { connection } from '../stores/connection';
import { library, syncLibrary } from '../stores/library';
import { connectServer, disconnect } from '../stores/connection';
import { IconButton } from './IconButton.tsrx';

export function Settings() {
  const serverUrl  = track('');
  const username   = track('');
  const password   = track('');
  const busy = track(false);
  const errorMsg   = track<string | null>(null);

  const conn = connection;
  const lib = library.state;

  const handleConnect = () => {
    haptic('medium');
    busy.value = true;
    errorMsg.value = null;
    connectServer(serverUrl.value, username.value, password.value)
      .then((result: any) => {
        busy.value = false;
        if (result?.connected) {
          conn.info.value = result;
          conn.status.value = 'connected';
        } else {
          errorMsg.value = result?.error ?? 'Connection failed';
        }
      })
      .catch((e: any) => {
        busy.value = false;
        errorMsg.value = String(e?.message ?? e);
      });
  };

  const handleSync = () => {
    haptic('medium');
    errorMsg.value = null;
    lib.syncing.value = true;
    syncLibrary()
      .then((result: any) => {
        lib.data.value = { artists: result.artists, albums: result.albums, songs: result.songs };
        lib.artistCount.value = result.artistCount;
        lib.albumCount.value = result.albumCount;
        lib.songCount.value = result.songCount;
        lib.lastSync.value = result.lastSync;
        lib.syncing.value = false;
      })
      .catch((e: any) => {
        lib.syncing.value = false;
        errorMsg.value = 'Sync failed: ' + String(e?.message ?? e);
      });
  };

  const handleDisconnect = () => {
    haptic('heavy');
    disconnect().then(() => {
      conn.info.value = { connected: false };
      conn.status.value = 'disconnected';
      lib.data.value = { artists: [], albums: [], songs: [] };
      lib.artistCount.value = 0;
      lib.albumCount.value = 0;
      lib.songCount.value = 0;
      lib.lastSync.value = null;
    }).catch(() => {});
  };

  return <>
    <div class="settings">
      <div class="section">
        <h3 class="section-title">{'Server Connection'}</h3>

        <div class="input-group">
          <label class="input-label">{'Server URL'}</label>
          <input class="input-field" type="url" placeholder="https://navidrome.example.com"
                 value={serverUrl.value} onInput={(e) => serverUrl.value = (e.target as HTMLInputElement).value} />
        </div>

        <div class="input-group">
          <label class="input-label">{'Username'}</label>
          <input class="input-field" type="text" placeholder="admin"
                 value={username.value} onInput={(e) => username.value = (e.target as HTMLInputElement).value} />
        </div>

        <div class="input-group">
          <label class="input-label">{'Password'}</label>
          <input class="input-field" type="password" placeholder="••••••••"
                 value={password.value} onInput={(e) => password.value = (e.target as HTMLInputElement).value} />
        </div>

        if (conn.status.value !== 'connected') {
          <IconButton icon="" label={busy.value ? 'Connecting...' : 'Connect'} variant="primary" size="lg" onClick={handleConnect} />
        } else {
          <IconButton icon="" label="Disconnect" variant="tertiary" size="lg" onClick={handleDisconnect} />
        }

        <div class="connection-status">
          switch (conn.status.value) {
            case 'connected':
              <span class="status-dot" data-state="connected" />
              <span class="status-text connected">{'Connected'}</span>
              break;
            case 'disconnected':
              <span class="status-dot" data-state="disconnected" />
              <span class="status-text disconnected">{'Disconnected'}</span>
              break;
          }
          if (errorMsg.value) {
            <span class="status-error">{errorMsg.value}</span>
          }
        </div>
      </div>

      if (conn.status.value === 'connected') {
        <div class="section">
          <h3 class="section-title">{'Sync'}</h3>
          <IconButton icon="" label={lib.syncing.value ? 'Syncing...' : 'Sync'} variant="secondary" size="lg" onClick={handleSync} />
          <div class="sync-stats">
            <div class="sync-row">
              <span class="sync-label">{'Songs'}</span>
              <span class="sync-value">{lib.songCount.value}</span>
            </div>
            <div class="sync-row">
              <span class="sync-label">{'Albums'}</span>
              <span class="sync-value">{lib.albumCount.value}</span>
            </div>
            <div class="sync-row">
              <span class="sync-label">{'Artists'}</span>
              <span class="sync-value">{lib.artistCount.value}</span>
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
        padding: var(--margin);
        display: flex;
        flex-direction: column;
        gap: var(--gutter);
      }

      .section {
        border: var(--border-width) solid var(--color-text);
        padding: clamp(14px, 3vw, 24px);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-lowest);
      }

      .section-title {
        font-family: var(--font-family);
        font-size: var(--fs-headline-md);
        font-weight: 800;
        letter-spacing: -0.02em;
        color: var(--color-text);
        margin: 0 0 16px 0;
        padding-bottom: 8px;
        border-bottom: var(--border-width) solid var(--color-text);
      }

      .input-group {
        display: flex;
        flex-direction: column;
        gap: 4px;
        margin-bottom: 14px;
      }

      .input-label {
        font-family: var(--font-family);
        font-size: var(--fs-label);
        font-weight: 600;
        color: var(--color-text-muted);
        letter-spacing: 0.04em;
      }

      .input-field {
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface);
        color: var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        font-weight: 400;
        padding: 10px 14px;
        outline: none;
        -webkit-appearance: none;
        box-sizing: border-box;
      }

      .input-field:focus {
        border-color: var(--color-secondary);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-secondary);
      }

      .input-field::placeholder {
        color: var(--color-text-muted);
        opacity: 0.5;
      }

      .connection-status {
        display: flex; align-items: center; gap: 10px;
        margin-top: 16px; flex-wrap: wrap;
      }

      .status-dot { width: 10px; height: 10px; flex-shrink: 0; }
      .status-dot[data-state='connected'] {
        background: var(--color-secondary);
        box-shadow: 0 0 8px var(--color-secondary-container);
      }
      .status-dot[data-state='disconnected'] {
        background: var(--color-text-muted);
      }

      .status-text {
        font-family: var(--font-family);
        font-size: var(--fs-label);
        font-weight: 600;
        letter-spacing: 0.04em;
      }
      .status-text.connected { color: var(--color-secondary); }
      .status-text.disconnected { color: var(--color-text-muted); }

      .status-error {
        width: 100%; font-size: var(--fs-metadata);
        color: var(--color-tertiary); margin-top: 4px; word-break: break-all;
        font-weight: 700;
      }

      .sync-stats {
        margin-top: 14px; display: flex; flex-direction: column; gap: 8px;
      }
      .sync-row {
        display: flex;
        justify-content: space-between;
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        font-weight: 400;
        padding: 6px 0;
        border-bottom: 2px solid var(--color-surface-variant);
      }
      .sync-row:last-child { border-bottom: none; }
      .sync-label { color: var(--color-text-muted); }
      .sync-value { color: var(--color-secondary); font-weight: 700; }

      .app-version {
        font-family: var(--font-family);
        font-size: var(--fs-body-bold);
        font-weight: 700;
        color: var(--color-secondary);
        margin: 0;
      }
      .app-credits {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        color: var(--color-text-muted);
        font-weight: 400;
        margin: 4px 0 0 0;
      }
    </style>
  </>;
}
