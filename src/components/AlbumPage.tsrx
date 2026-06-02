import { track } from 'ripple';
import { haptic, setQueue, addToQueue, getCoverArtUrl, playSong } from '../stores/now-playing';
import { library } from '../stores/library';
import { router, navigate } from '../stores/router';
import { formatTime } from '../state';
import { IconButton } from './IconButton.tsrx';
import { TrackRow } from './TrackRow.tsrx';

export function AlbumPage() {
  const lib = library.state;
  const rt = router.state;

  const albumId = router.selectedAlbum.id.value;
  const albumName = router.selectedAlbum.name.value;
  const artistName = router.selectedAlbum.artistName.value;

  const songs = track(() => lib.data.value.songs
    .filter(s => s.albumId === albumId)
    .sort((a, b) => a.track - b.track)
  );

  return <>
    <div class="album-page">
      <div class="album-header">
        <IconButton icon="\u2190" size="sm" onClick={() => {
          haptic('light');
          navigate('library');
        }} />
        <div class="album-info">
          <div class="album-title">{albumName}</div>
          <div class="album-by">{artistName}</div>
        </div>
      </div>
      <div class="album-art">
        <div class="album-art__placeholder">{'\u25C9'}</div>
        <div class="album-art__year">{'LP / 2024'}</div>
        <div class="album-art__badge">{'STEREO'}</div>
      </div>
      <div class="album-meta">
        <div class="album-meta__header">
          <h2 class="album-meta__title">{albumName}</h2>
          <p class="album-meta__artist">{artistName}</p>
        </div>
        <div class="album-meta__actions">
          <IconButton icon="" label="Play All" variant="primary" size="lg" onClick={async () => {
            haptic('light');
            const first = songs.value[0];
            if (first) {
              setQueue(first);
              const covUrl = await getCoverArtUrl(first.coverArt);
              await playSong(first, covUrl);
            }
          }} />
          <IconButton icon="" label="Save" variant="secondary" size="lg" onClick={() => {
            haptic('light');
          }} />
        </div>
      </div>
      <div class="album-tracklist-header">
        <span>{`Tracks \u00B7 ${songs.value.length} \u00B7 ${formatTime(songs.value.reduce((a, s) => a + s.duration, 0))}`}</span>
      </div>
      <div class="album-tracks">
        if (songs.value.length === 0) {
          <div class="empty-msg">{'No tracks found.'}</div>
        } else {
          for (const s of songs.value; index i) {
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

    <style>
      .album-page {
        display: flex;
        flex-direction: column;
        height: 100%;
      }

      .album-header {
        flex-shrink: 0;
        display: flex;
        align-items: center;
        gap: 14px;
        padding: var(--gutter) var(--margin);
        border-bottom: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-elevated);
      }

      .album-info {
        flex: 1;
        overflow: hidden;
      }

      .album-title {
        font-family: var(--font-family);
        font-size: var(--fs-body-bold);
        font-weight: 800;
        color: var(--color-text);
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .album-by {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        color: var(--color-text-muted);
        font-weight: 400;
        margin-top: 2px;
      }

      .album-art {
        aspect-ratio: 1;
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset-lg) var(--shadow-offset-lg) 0 var(--color-text);
        background: var(--color-primary-container);
        display: flex;
        align-items: center;
        justify-content: center;
        margin: var(--margin);
        position: relative;
        overflow: hidden;
      }

      .album-art__placeholder {
        font-size: clamp(4rem, 15vw, 8rem);
        color: var(--color-on-primary-container);
        opacity: 0.5;
      }

      .album-art__year {
        position: absolute;
        top: 0;
        left: 0;
        padding: var(--unit) var(--gutter);
        background: var(--color-primary);
        color: var(--color-on-primary);
        border-right: var(--border-width) solid var(--color-text);
        border-bottom: var(--border-width) solid var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
      }

      .album-art__badge {
        position: absolute;
        bottom: 0;
        right: 0;
        padding: var(--unit) var(--gutter);
        background: var(--color-tertiary);
        color: var(--color-on-tertiary);
        border-left: var(--border-width) solid var(--color-text);
        border-top: var(--border-width) solid var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
      }

      .album-meta {
        display: flex;
        flex-direction: column;
        gap: var(--gutter);
        padding: 0 var(--margin);
      }

      .album-meta__header {
        text-align: center;
      }

      .album-meta__title {
        font-family: var(--font-family);
        font-size: var(--fs-headline-md);
        font-weight: 900;
        line-height: var(--lh-headline);
        color: var(--color-text);
        margin: 0;
        word-break: break-word;
      }

      .album-meta__artist {
        font-family: var(--font-family);
        font-size: var(--fs-body-bold);
        font-weight: 700;
        color: var(--color-primary);
        margin: 6px 0 0 0;
      }

      .album-meta__actions {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: var(--gutter);
      }

      .album-tracklist-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin: var(--margin) var(--margin) 0 var(--margin);
        padding: 6px 12px;
        border: var(--border-width) solid var(--color-text);
        background: var(--color-text);
        color: var(--color-surface-lowest);
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.06em;
      }

      .album-tracks {
        flex: 1;
        overflow-y: auto;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior-y: contain;
        margin: 0 var(--margin) var(--margin) var(--margin);
        border: var(--border-width) solid var(--color-text);
        border-top: none;
        box-shadow: var(--shadow-offset-lg) var(--shadow-offset-lg) 0 var(--color-text);
        background: var(--color-surface-lowest);
      }

      .empty-msg {
        text-align: center;
        padding: 48px 0;
        color: var(--color-text-muted);
        font-family: var(--font-family);
        font-size: var(--fs-body-reg);
        font-weight: 400;
      }
    </style>
  </>;
}
