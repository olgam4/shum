import { invoke } from "@tauri-apps/api/core";
import { Context, track, type Tracked } from "ripple";
import {
  initialize,
  setSource,
  play,
  pause,
  seekTo,
  dispose,
  addStateListener,
} from "tauri-plugin-native-audio-api";
import type {
  TrackMeta,
  PlaybackState,
  NativeAudioState,
  LibrarySong,
  CacheProgress,
} from "../types";

const trackCtx = new Context<{ current: Tracked<TrackMeta | null> }>(
  {} as never,
);
const playbackCtx = new Context<{
  state: Tracked<PlaybackState>;
  progress: Tracked<number>;
  duration: Tracked<number>;
  volume: Tracked<number>;
}>({} as never);
const queueCtx = new Context<{
  items: Tracked<LibrarySong[]>;
  index: Tracked<number>;
}>({} as never);
const playerOpenCtx = new Context<{ open: Tracked<boolean> }>({} as never);
const playerClosingCtx = new Context<{ closing: Tracked<boolean> }>(
  {} as never,
);

let _trackObj: ReturnType<typeof trackCtx.get>;
let _playbackObj: ReturnType<typeof playbackCtx.get>;
let _queueObj: ReturnType<typeof queueCtx.get>;
let _playerOpenObj: ReturnType<typeof playerOpenCtx.get>;
let _playerClosingObj: ReturnType<typeof playerClosingCtx.get>;

let _onPlayStart: ((meta: TrackMeta) => void) | null = null;
let _onStop: (() => void) | null = null;
let _onAudioState: ((state: NativeAudioState) => void) | null = null;
let _audioReady = false;
let _unlistenAudio: (() => void) | null = null;

function _registerStateListener() {
  addStateListener((state: NativeAudioState) => {
    _onAudioState?.(state);
  }).then((fn) => (_unlistenAudio = fn));
}

export function applyAudioState(state: NativeAudioState): void {
  const p = _playbackObj;
  p.progress.value = state.currentTime;
  p.duration.value = state.duration;
  if (state.isPlaying) p.state.value = "playing";
  else if (state.status === "loading" || state.buffering)
    p.state.value = "buffering";
  else if (state.status === "error") p.state.value = "error";
  else if (state.status === "ended") {
    p.state.value = "stopped";
    const q = _queueObj;
    if (q.index.value + 1 < q.items.value.length) {
      const next = q.items.value[q.index.value + 1];
      nextInQueue()
        .then(() => {
          getCoverArtUrl(next.coverArt)
            .then((covUrl) => {
              playSong(next, covUrl).catch(() => {});
            })
            .catch(() => {});
        })
        .catch(() => {});
    } else {
      _trackObj.current.value = null;
      requestStop().catch(() => {});
    }
  } else p.state.value = "paused";
}

export function setOnPlayStart(fn: (meta: TrackMeta) => void) {
  _onPlayStart = fn;
}
export function setOnStop(fn: () => void) {
  _onStop = fn;
}
export function setOnAudioState(fn: (state: NativeAudioState) => void) {
  _onAudioState = fn;
}

export function initNowPlaying() {
  _trackObj = trackCtx.get();
  _trackObj.current = track<TrackMeta | null>(null);

  _playbackObj = playbackCtx.get();
  _playbackObj.state = track<PlaybackState>("stopped");
  _playbackObj.progress = track(0);
  _playbackObj.duration = track(0);
  _playbackObj.volume = track(0.75);

  _queueObj = queueCtx.get();
  _queueObj.items = track<LibrarySong[]>([]);
  _queueObj.index = track(0);

  _playerOpenObj = playerOpenCtx.get();
  _playerOpenObj.open = track(false);

  _playerClosingObj = playerClosingCtx.get();
  _playerClosingObj.closing = track(false);

  setOnPlayStart((meta: TrackMeta) => {
    _trackObj.current.value = meta;
    _playbackObj.state.value = "playing";
  });
  setOnStop(() => {
    _trackObj.current.value = null;
    _playbackObj.state.value = "stopped";
  });
  setOnAudioState(applyAudioState);
}

export const nowPlaying = {
  get track() {
    return _trackObj;
  },
  get playback() {
    return _playbackObj;
  },
  get queue() {
    return _queueObj;
  },
  get playerOpen() {
    return _playerOpenObj;
  },
  get playerClosing() {
    return _playerClosingObj;
  },
};

export async function initAudio() {
  if (_audioReady) return;
  await initialize();
  _audioReady = true;
  _registerStateListener();
}

export async function playSong(song: LibrarySong, coverArtUrl: string) {
  const streamUrl = await invoke<string>("get_stream_url", { id: song.id });
  return playUrl(song, streamUrl, coverArtUrl);
}

export async function playUrl(
  song: LibrarySong,
  streamUrl: string,
  coverArtUrl: string,
) {
  if (!_audioReady) {
    await initialize();
    _audioReady = true;
    _registerStateListener();
  }
  _onPlayStart?.({
    id: song.id,
    title: song.title,
    artist: song.artist,
    artistId: song.artistId,
    album: song.album,
    albumId: song.albumId,
    durationSecs: song.duration,
    coverArtUrl: coverArtUrl || null,
    contentType: song.contentType,
    suffix: song.suffix,
  });
  await setSource({
    src: streamUrl,
    title: song.title,
    artist: song.artist,
    artworkUrl: coverArtUrl || undefined,
  });
  return play();
}

export async function playLocal(
  song: LibrarySong,
  localPath: string,
  coverArtUrl: string,
) {
  if (!_audioReady) {
    await initialize();
    _audioReady = true;
    _registerStateListener();
  }
  _onPlayStart?.({
    id: song.id,
    title: song.title,
    artist: song.artist,
    artistId: song.artistId,
    album: song.album,
    albumId: song.albumId,
    durationSecs: song.duration,
    coverArtUrl: coverArtUrl || null,
    contentType: song.contentType,
    suffix: song.suffix,
  });
  await setSource({
    src: `file://${localPath}`,
    title: song.title,
    artist: song.artist,
    artworkUrl: coverArtUrl || undefined,
  });
  return play();
}

export function requestPlay(track: TrackMeta | null) {
  if (track) return play();
  return Promise.resolve();
}

export function requestPause() {
  return pause();
}

export function requestStop() {
  _onStop?.();
  _unlistenAudio?.();
  _unlistenAudio = null;
  _audioReady = false;
  return dispose();
}

export function requestSeek(pos: number) {
  return seekTo(pos);
}

export function setQueue(song: LibrarySong) {
  _queueObj.items.value = [song];
  _queueObj.index.value = 0;
}

export function addToQueue(song: LibrarySong) {
  _queueObj.items.value = [..._queueObj.items.value, song];
}

export function nextInQueue() {
  _queueObj.index.value += 1;
  if (_queueObj.index.value >= _queueObj.items.value.length) {
    _queueObj.index.value = 0;
    _queueObj.items.value = [];
  }
  return Promise.resolve();
}

export async function getStreamUrl(id: string): Promise<string> {
  return invoke("get_stream_url", { id });
}

export async function getCoverArtUrl(id: string): Promise<string> {
  return invoke("get_cover_art_url", { id });
}

export function cacheSong(id: string): Promise<CacheProgress> {
  return invoke("cache_song", { id });
}

export function getCachedSongPath(id: string): Promise<string | null> {
  return invoke("get_cached_song_path", { id });
}

export async function haptic(
  type: "light" | "medium" | "heavy" | "success" | "error" | "selection",
) {
  try {
    if (type === "light" || type === "medium" || type === "heavy") {
      await invoke("plugin:haptics|impact_feedback", { type });
    } else if (type === "success" || type === "error") {
      await invoke("plugin:haptics|notification_feedback", { type });
    } else if (type === "selection") {
      await invoke("plugin:haptics|selection_feedback");
    }
  } catch {
    /* noop */
  }
}
