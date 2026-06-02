import { track } from 'ripple';
import { haptic, setQueue, addToQueue, getCoverArtUrl, playSong } from '../stores/now-playing';
import { library } from '../stores/library';
import { router, navigateToAlbum, navigate } from '../stores/router';
import { formatTime } from '../state';
import { Badge } from './Badge.tsrx';
import { Chip } from './Chip.tsrx';
import { TrackRow } from './TrackRow.tsrx';
import { IconButton } from './IconButton.tsrx';

export function ArtistPage() {
  const lib = library.state;
  const rt = router.state;

  const artistId = router.selectedArtist.id.value;
  const artistName = router.selectedArtist.name.value;

  const albums = track(() => lib.data.value.albums.filter(a => a.artistId === artistId));
  const topSongs = track(() => lib.data.value.songs
    .filter(s => s.artistId === artistId)
    .sort((a, b) => a.track - b.track)
    .slice(0, 4)
  );

  return <>
    <div class="artist-page">
      <div class="artist-hero">
        <div class="artist-hero__bg" />
        <div class="artist-hero__content">
          <div class="artist-hero__badges">
            <Badge variant="accent">{'Artist'}</Badge>
            <Badge>{`${albums.value.length} albums`}</Badge>
          </div>
          <h1 class="artist-hero__name">{artistName}</h1>
          <div class="artist-hero__actions">
            <IconButton
              icon=""
              label="Play Latest"
              variant="primary"
              size="lg"
              onClick={async () => {
                haptic('light');
                const first = topSongs.value[0];
                if (first) {
                  setQueue(first);
                  const covUrl = await getCoverArtUrl(first.coverArt);
                  await playSong(first, covUrl);
                }
              }}
            />
            <IconButton icon="" label="Follow" size="lg" onClick={() => {
              haptic('light');
            }} />
          </div>
        </div>
      </div>

      <div class="artist-layout">
        <div class="artist-top-tracks">
          <h2 class="section-title">{'Top Tracks'}</h2>
          <div class="top-tracks-list">
            if (topSongs.value.length === 0) {
              <div class="empty-msg">{'No tracks found.'}</div>
            } else {
              for (const s of topSongs.value; index i) {
                <TrackRow
                  song={s}
                  index={i}
                  onPlay={async () => {
                    haptic('light');
                    setQueue(s);
                    const covUrl = await getCoverArtUrl(s.coverArt);
                    await playSong(s, covUrl);
                  }}
                  onAdd={(e: Event) => {
                    e.stopPropagation();
                    haptic('selection');
                    addToQueue(s);
                  }}
                />
              }
            }
          </div>
        </div>

        <div class="artist-albums">
          <h2 class="section-title">{'Albums'}</h2>
          <div class="album-grid">
            if (albums.value.length === 0) {
              <div class="empty-msg">{'No albums found.'}</div>
            } else {
              for (const a of albums.value; index i) {
                <button class="album-tile" style={{ '--i': String(i) }} onClick={() => {
                  haptic('light');
                  navigateToAlbum(a.id, a.name, a.artistId, artistName);
                }}>
                  <div class="tile-art">{'\u25C9'}</div>
                  <div class="tile-name">{a.name}</div>
                  <div class="tile-meta">{`${a.year || '\u2014'} \u00B7 ${a.songCount} songs`}</div>
                </button>
              }
            }
          </div>
        </div>
      </div>
    </div>

    <style>
      .artist-page {
        display: flex;
        flex-direction: column;
        height: 100%;
      }

      .artist-hero {
        position: relative;
        min-height: clamp(240px, 40vh, 360px);
        display: flex;
        align-items: flex-end;
        background: var(--color-primary-container);
        border-bottom: var(--border-width) solid var(--color-text);
        overflow: hidden;
      }

      .artist-hero__bg {
        position: absolute;
        inset: 0;
        opacity: 0.15;
        pointer-events: none;
        background-image: radial-gradient(circle, var(--color-text) 2px, transparent 2px);
        background-size: 20px 20px;
      }

      .artist-hero__content {
        position: relative;
        z-index: 10;
        width: 100%;
        padding: var(--margin);
        display: flex;
        flex-direction: column;
        gap: var(--gutter);
      }

      .artist-hero__badges {
        display: flex;
        gap: var(--gutter);
        flex-wrap: wrap;
      }

      .artist-hero__name {
        font-family: var(--font-family);
        font-size: var(--fs-headline-xl);
        font-weight: 900;
        letter-spacing: -0.04em;
        line-height: var(--lh-headline-xl);
        color: var(--color-text);
        margin: 0;
        word-break: break-word;
      }

      .artist-hero__actions {
        display: flex;
        gap: var(--gutter);
        flex-wrap: wrap;
      }

      .artist-layout {
        flex: 1;
        overflow-y: auto;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-y: contain;
        display: flex;
        flex-direction: column;
        gap: var(--margin);
        padding: var(--margin);
      }

      .section-title {
        font-family: var(--font-family);
        font-size: var(--fs-headline-md);
        font-weight: 800;
        letter-spacing: -0.02em;
        line-height: var(--lh-headline);
        color: var(--color-text);
        margin: 0 0 var(--gutter) 0;
        padding-bottom: 8px;
        border-bottom: var(--border-width) solid var(--color-text);
      }

      .top-tracks-list {
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-lowest);
      }

      .album-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(clamp(140px, 40vw, 200px), 1fr));
        gap: var(--gutter);
      }

      .album-tile {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 8px;
        padding: clamp(12px, 3vw, 18px);
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-lowest);
        cursor: pointer;
        text-align: center;
        font-family: var(--font-family);
        -webkit-tap-highlight-color: transparent;
        outline: none;
        transition: transform 0.05s ease, box-shadow 0.05s ease;
      }

      .album-tile:active {
        transform: translate(var(--shadow-offset), var(--shadow-offset));
        box-shadow: none;
      }

      .album-tile {
        animation: tile-enter 0.4s ease both;
        animation-delay: calc(var(--i, 0) * 40ms);
      }

      @keyframes tile-enter {
        from { opacity: 0; transform: translateY(12px) scale(0.95); }
        to { opacity: 1; transform: translateY(0) scale(1); }
      }

      .tile-art {
        font-size: clamp(2rem, 8vw, 3.5rem);
        color: var(--color-secondary);
        line-height: 1;
      }

      .tile-name {
        font-family: var(--font-family);
        font-size: var(--fs-body-bold);
        font-weight: 800;
        color: var(--color-text);
        overflow: hidden;
        text-overflow: ellipsis;
        width: 100%;
        white-space: nowrap;
      }

      .tile-meta {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 400;
        color: var(--color-text-muted);
      }

      .empty-msg {
        text-align: center;
        padding: 32px 0;
        color: var(--color-text-muted);
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        font-weight: 400;
      }
    </style>
  </>;
}
