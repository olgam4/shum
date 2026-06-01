import { Context, track, type Tracked } from 'ripple';
import type { TrackMeta, PlaybackState, ConnectionInfo, ConnectionStatus, SearchResult, Route, LibrarySong } from './types';

const trackCtx = new Context<{ current: Tracked<TrackMeta | null> }>({} as never);
const playbackCtx = new Context<{
  state: Tracked<PlaybackState>;
  progress: Tracked<number>;
  duration: Tracked<number>;
  volume: Tracked<number>;
}>({} as never);
const libraryCtx = new Context<{
  data: Tracked<SearchResult>;
  artistCount: Tracked<number>;
  albumCount: Tracked<number>;
  songCount: Tracked<number>;
  lastSync: Tracked<string | null>;
  syncing: Tracked<boolean>;
}>({} as never);
const connectionCtx = new Context<{
  status: Tracked<ConnectionStatus>;
  info: Tracked<ConnectionInfo>;
}>({} as never);
const routeCtx = new Context<{ current: Tracked<Route> }>({} as never);
const playerOpenCtx = new Context<{ open: Tracked<boolean> }>({} as never);
const queueCtx = new Context<{
  items: Tracked<LibrarySong[]>;
  index: Tracked<number>;
}>({} as never);
const selectedArtistCtx = new Context<{ id: Tracked<string>; name: Tracked<string> }>({} as never);
const selectedAlbumCtx = new Context<{ id: Tracked<string>; name: Tracked<string>; artistId: Tracked<string>; artistName: Tracked<string> }>({} as never);

let _trackObj: ReturnType<typeof trackCtx.get>;
let _playbackObj: ReturnType<typeof playbackCtx.get>;
let _libraryObj: ReturnType<typeof libraryCtx.get>;
let _connectionObj: ReturnType<typeof connectionCtx.get>;
let _routeObj: ReturnType<typeof routeCtx.get>;
let _playerOpenObj: ReturnType<typeof playerOpenCtx.get>;
let _queueObj: ReturnType<typeof queueCtx.get>;
let _selectedArtistObj: ReturnType<typeof selectedArtistCtx.get>;
let _selectedAlbumObj: ReturnType<typeof selectedAlbumCtx.get>;

export function initContexts() {
  _trackObj = trackCtx.get();
  _trackObj.current = track<TrackMeta | null>(null);

  _playbackObj = playbackCtx.get();
  _playbackObj.state = track<PlaybackState>('stopped');
  _playbackObj.progress = track(0);
  _playbackObj.duration = track(0);
  _playbackObj.volume = track(0.75);

  _libraryObj = libraryCtx.get();
  _libraryObj.data = track<SearchResult>({ artists: [], albums: [], songs: [] });
  _libraryObj.artistCount = track(0);
  _libraryObj.albumCount = track(0);
  _libraryObj.songCount = track(0);
  _libraryObj.lastSync = track<string | null>(null);
  _libraryObj.syncing = track(false);

  _connectionObj = connectionCtx.get();
  _connectionObj.status = track<ConnectionStatus>('disconnected');
  _connectionObj.info = track<ConnectionInfo>({ connected: false });

  _routeObj = routeCtx.get();
  _routeObj.current = track<Route>('home');

  _playerOpenObj = playerOpenCtx.get();
  _playerOpenObj.open = track(false);

  _queueObj = queueCtx.get();
  _queueObj.items = track<LibrarySong[]>([]);
  _queueObj.index = track(0);

  _selectedArtistObj = selectedArtistCtx.get();
  _selectedArtistObj.id = track('');
  _selectedArtistObj.name = track('');

  _selectedAlbumObj = selectedAlbumCtx.get();
  _selectedAlbumObj.id = track('');
  _selectedAlbumObj.name = track('');
  _selectedAlbumObj.artistId = track('');
  _selectedAlbumObj.artistName = track('');
}

export const ctx = {
  get track() { return _trackObj; },
  get playback() { return _playbackObj; },
  get library() { return _libraryObj; },
  get connection() { return _connectionObj; },
  get route() { return _routeObj; },
  get playerOpen() { return _playerOpenObj; },
  get queue() { return _queueObj; },
  get selectedArtist() { return _selectedArtistObj; },
  get selectedAlbum() { return _selectedAlbumObj; },
};

export { trackCtx, playbackCtx, libraryCtx, connectionCtx, routeCtx, playerOpenCtx, queueCtx, selectedArtistCtx, selectedAlbumCtx };
