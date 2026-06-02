import { effect } from "ripple";
import { nowPlaying } from "./stores/now-playing";
import { requestPlay, requestPause, nextInQueue } from "./stores/now-playing";

export function setupMediaSession() {
  effect(() => {
    const meta = nowPlaying.track.current.value;
    if (
      !meta ||
      typeof navigator === "undefined" ||
      !("mediaSession" in navigator)
    )
      return;

    const artwork: MediaImage[] = [];
    if (meta.coverArtUrl) {
      artwork.push({
        src: meta.coverArtUrl,
        sizes: "512x512",
        type: "image/jpeg",
      });
    }

    navigator.mediaSession.metadata = new MediaMetadata({
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      artwork,
    });
  });

  effect(() => {
    if (typeof navigator === "undefined" || !("mediaSession" in navigator))
      return;
    const state = nowPlaying.playback.state.value;
    navigator.mediaSession.playbackState =
      state === "playing" ? "playing" : "paused";
  });

  if (typeof navigator !== "undefined" && "mediaSession" in navigator) {
    navigator.mediaSession.setActionHandler("play", () => {
      const t = nowPlaying.track.current.value;
      if (t) requestPlay(t);
    });
    navigator.mediaSession.setActionHandler("pause", () => requestPause());
    navigator.mediaSession.setActionHandler("nexttrack", () => {
      nextInQueue().catch(() => {});
    });
    navigator.mediaSession.setActionHandler("previoustrack", null);
    navigator.mediaSession.setActionHandler("seekto", null);
  }
}
