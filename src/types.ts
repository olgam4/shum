export interface TrackMeta {
  id: string;
  title: string;
  artist: string;
  artistId: string;
  album: string;
  albumId: string;
  durationSecs: number;
  coverArtUrl: string | null;
  contentType: string;
  suffix: string;
}

export type PlaybackState = 'playing' | 'paused' | 'stopped' | 'buffering' | 'error';

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

export interface SyncResult {
  artists: LibraryArtist[];
  albums: LibraryAlbum[];
  songs: LibrarySong[];
  artistCount: number;
  albumCount: number;
  songCount: number;
  lastSync: string | null;
}

export interface StartupState {
  connectionStatus: ConnectionInfo;
  library: SyncResult | null;
}

export interface CacheProgress {
  songId: string;
  status: 'downloading' | 'complete' | 'error';
  localPath?: string;
}

export type Route = 'home' | 'library' | 'settings' | 'artist' | 'album';

export type NativeAudioStatus = 'idle' | 'loading' | 'playing' | 'ended' | 'error';

export interface NativeAudioState {
  status: NativeAudioStatus;
  currentTime: number;
  duration: number;
  isPlaying: boolean;
  buffering: boolean;
  rate: number;
  error?: string;
}
