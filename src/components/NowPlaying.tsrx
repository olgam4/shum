import type { TrackMeta, PlaybackState } from '../types';
import type { Tracked } from 'ripple';

export function NowPlaying(&{ track, playbackState }: {
  track: Tracked<TrackMeta | null>;
  playbackState: Tracked<PlaybackState>;
}) {
  return <>
    <div class="np-root">
      <div class="album-art-container">
        if (track?.coverArtUrl) {
          <img class="album-art" src={track.coverArtUrl} alt={track.album} />
        } else {
          <div class="album-art-placeholder">
            <span class="placeholder-glyph" data-state={playbackState}>
              {playbackState === 'playing' ? '⋆' : '□'}
            </span>
          </div>
        }
      </div>

      <div class="track-info">
        <div class="marquee-wrap">
          <span class="track-title" data-state={playbackState}>{track?.title ?? '—'}</span>
        </div>
        <p class="track-artist">{track?.artist ?? 'Unknown Artist'}</p>
        <p class="track-album">{track?.album ?? ''}</p>
      </div>
    </div>

    <style>
      .np-root {
        width: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: clamp(14px, 2.5vh, 24px);
      }

      .album-art-container {
        width: clamp(180px, 50vw, 280px);
        height: clamp(180px, 50vw, 280px);
        border: var(--shum-border) solid var(--shum-color-accent);
        overflow: hidden;
        box-shadow: var(--shum-shadow) var(--shum-shadow) 0px var(--shum-color-brand);
        flex-shrink: 0;
      }

      .album-art {
        width: 100%;
        height: 100%;
        object-fit: cover;
        display: block;
      }

      .album-art-placeholder {
        width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        background: var(--shum-color-surface);
      }

      .placeholder-glyph {
        font-size: clamp(3rem, 8vw, 5rem);
        color: var(--shum-color-brand);
        opacity: 0.5;
      }

      .placeholder-glyph[data-state='playing'] {
        opacity: 1;
        color: var(--shum-color-accent);
        animation: glyph-pulse 1.4s ease-in-out infinite;
      }

      .placeholder-glyph[data-state='buffering'] {
        color: var(--shum-color-danger);
        animation: glyph-pulse 0.6s step-end infinite;
      }

      @keyframes glyph-pulse {
        0%, 100% { opacity: 0.4; transform: scale(1); }
        50% { opacity: 1; transform: scale(1.12); }
      }

      .track-info {
        width: 100%;
        text-align: center;
        overflow: hidden;
      }

      .marquee-wrap {
        width: 100%;
        overflow: hidden;
        white-space: nowrap;
        position: relative;
      }

      .track-title {
        display: inline-block;
        font-size: clamp(1.25rem, 4vw, 1.75rem);
        font-weight: 800;
        color: var(--shum-color-brand);
        letter-spacing: -0.02em;
        animation: marquee 8s linear infinite paused;
        padding-right: 50px;
      }

      .track-title[data-state='playing'] {
        animation-play-state: running;
      }

      @keyframes marquee {
        0% { transform: translateX(0); }
        100% { transform: translateX(-100%); }
      }

      .track-artist {
        font-size: clamp(0.875rem, 2.5vw, 1.125rem);
        color: var(--shum-color-accent);
        font-weight: 700;
        margin: 4px 0 0 0;
      }

      .track-album {
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        color: var(--shum-color-text-muted);
        margin: 2px 0 0 0;
      }
    </style>
  </>;
}
