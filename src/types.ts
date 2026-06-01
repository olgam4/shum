export interface TrackMeta {
  id: string;
  title: string;
  artist: string;
  album: string;
  durationSecs: number;
  coverArtUrl: string | null;
}

export type PlaybackState = 'playing' | 'paused' | 'stopped' | 'buffering';

export interface AudioState {
  currentTrack: TrackMeta | null;
  playbackState: PlaybackState;
  volume: number;
  positionSecs: number;
}

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected';

export interface ConnectionInfo {
  connected: boolean;
  serverName?: string;
  serverVersion?: string;
  error?: string;
}

export interface LibrarySong {
  id: string;
  title: string;
  artist: string;
  album: string;
  artistId: string;
  albumId: string;
  duration: number;
  track: number;
  year: number;
  contentType: string;
  suffix: string;
  coverArt: string;
  size: number;
  bitRate: number;
}

export interface LibraryAlbum {
  id: string;
  name: string;
  artist: string;
  artistId: string;
  year: number;
  coverArt: string;
  songCount: number;
  duration: number;
}

export interface LibraryArtist {
  id: string;
  name: string;
  coverArt: string;
  albumCount: number;
}

export interface SearchResult {
  artists: LibraryArtist[];
  albums: LibraryAlbum[];
  songs: LibrarySong[];
}

export interface LibrarySnapshot {
  artistCount: number;
  albumCount: number;
  songCount: number;
  lastSync: string;
}

export interface CacheProgress {
  songId: string;
  status: 'downloading' | 'complete' | 'error';
  localPath?: string;
}

export type Route = 'home' | 'library' | 'settings';
