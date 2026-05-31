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
