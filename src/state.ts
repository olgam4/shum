import { track } from "ripple";
import { nowPlaying } from "./stores/now-playing";

const _isPlaying = track(() => nowPlaying.playback.state.value === "playing");
const _progressPct = track(() => {
  const p = nowPlaying.playback;
  return p.duration.value > 0 ? (p.progress.value / p.duration.value) * 100 : 0;
});
const _volumePct = track(() =>
  Math.round(nowPlaying.playback.volume.value * 100),
);

export const computed = {
  isPlaying: _isPlaying,
  progressPct: _progressPct,
  volumePct: _volumePct,
};

export function formatTime(secs: number): string {
  if (!secs || secs <= 0) return "0:00";
  const m = Math.floor(secs / 60);
  const s = Math.floor(secs % 60);
  return `${m}:${s.toString().padStart(2, "0")}`;
}
