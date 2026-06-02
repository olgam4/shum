import { nowPlaying, requestPlay, requestPause, haptic } from '../stores/now-playing';
import { router, navigateToArtist } from '../stores/router';

export function NowPlayingWidget() {
  const tk = nowPlaying.track;
  const pb = nowPlaying.playback;
  const po = nowPlaying.playerOpen;

  return <>
    <div class="widget" onClick={() => {
      haptic('light');
      po.open.value = true;
    }}>
      <div class="widget-progress-bar">
        <div class="widget-progress-fill" style={{ '--p': 0 }} />
      </div>
      <div class="widget-inner">
        <div class="widget-info">
          <span class="widget-title">{tk.current.value?.title ?? '\u2014'}</span>
          <span class="widget-artist">
            <button class="widget-artist-btn" onClick={(e: Event) => {
              e.stopPropagation();
              if (tk.current.value?.artistId) {
                haptic('light');
                router.selectedArtist.id.value = tk.current.value.artistId;
                router.selectedArtist.name.value = tk.current.value.artist;
                po.open.value = false;
                navigateToArtist(tk.current.value.artistId, tk.current.value.artist);
              }
            }}>
              {tk.current.value?.artist ?? ''}
            </button>
            if (tk.current.value?.suffix) {
              <span class="widget-format">{` \u00B7 ${tk.current.value.suffix.toUpperCase()}`}</span>
            }
          </span>
        </div>
        <button class="widget-play-btn" onClick={(e: Event) => {
          e.stopPropagation();
          haptic('light');
          if (pb.state.value === 'playing') requestPause();
          else requestPlay(tk.current.value);
        }}>
          {pb.state.value === 'playing' ? '\u23F8' : '\u25B6'}
        </button>
      </div>
    </div>

    <style>
      .widget {
        width: 100%;
        flex-shrink: 0;
        height: var(--widget-height);
        background: var(--color-surface-elevated);
        border-top: var(--border-width) solid var(--color-text);
        box-shadow: 0 -2px 0 var(--color-text);
        cursor: pointer;
        z-index: 99;
        -webkit-tap-highlight-color: transparent;
      }

      .widget:active {
        background: var(--color-surface-variant);
      }

      .widget-progress-bar {
        height: 3px;
        background: var(--color-surface);
      }

      .widget-progress-fill {
        height: 100%;
        width: calc(var(--p) * 1%);
        background: var(--color-primary);
        transition: width 0.3s linear;
      }

      .widget-inner {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 clamp(12px, 3vw, 16px);
        min-height: var(--widget-height);
      }

      .widget-info {
        display: flex;
        flex-direction: column;
        gap: 1px;
        overflow: hidden;
        flex: 1;
      }

      .widget-title {
        font-family: var(--font-family);
        font-size: var(--fs-body-bold);
        font-weight: 700;
        color: var(--color-text);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .widget-artist {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        color: var(--color-text-muted);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        display: flex;
        align-items: center;
      }

      .widget-artist-btn {
        font-family: var(--font-family);
        font-size: inherit;
        color: var(--color-secondary);
        background: transparent;
        border: none;
        padding: 0;
        cursor: pointer;
        font-weight: 700;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        text-decoration: underline;
        text-decoration-color: var(--color-secondary-container);
        text-underline-offset: 2px;
        -webkit-tap-highlight-color: transparent;
        outline: none;
      }

      .widget-artist-btn:active {
        opacity: 0.6;
      }

      .widget-format {
        font-weight: 700;
        color: var(--color-text-muted);
        opacity: 0.5;
        font-size: clamp(0.5rem, 1.1vw, 0.6rem);
      }

      .widget-play-btn {
        flex-shrink: 0;
        width: var(--tap-min);
        height: var(--tap-min);
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-lowest);
        color: var(--color-text);
        font-size: clamp(0.875rem, 2.5vw, 1rem);
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        transition: transform 0.05s ease, box-shadow 0.05s ease;
      }

      .widget-play-btn:active {
        transform: translate(var(--shadow-offset), var(--shadow-offset));
        box-shadow: none;
      }
    </style>
  </>;
}
