# Шум

[![Tauri v2](https://img.shields.io/badge/tauri-v2.11-blue)](https://v2.tauri.app/)
[![Ripple-TS](https://img.shields.io/badge/ripple--ts-latest-yellow)](https://www.ripple-ts.com/)
[![Rust](https://img.shields.io/badge/rust-stable-orange)](https://www.rust-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A self-hosted music streaming app for iOS that connects to a [Navidrome](https://www.navidrome.org/) server.

**All audio state lives in Rust.** The frontend is a passive render surface — it does not hold, mutate, or decide playback state. It displays what Rust tells it to display.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Rust (src-tauri/)                         │
│                                                                  │
│  ┌────────────────────────┐    ┌──────────────────────────────┐ │
│  │   AudioPlatform (trait) │    │  AudioManager<P>             │ │
│  │                        │    │                              │ │
│  │   load()    play()     │◄───│  Arc<Mutex<AudioState>>      │ │
│  │   pause()   stop()     │    │  ├─ current_track            │ │
│  │   seek()    set_vol()  │    │  ├─ playback_state           │ │
│  │                        │    │  ├─ volume                   │ │
│  │   NativeAudio           │    │  └─ position_secs            │ │
│  │   (AVAudioEngine stub)  │    └──────────────┬───────────────┘ │
│  └────────────┬───────────┘                    │                 │
│               │                  ┌─────────────▼──────────────┐  │
│               │                  │  Tauri v2 Commands          │  │
│               │                  │                             │  │
│               │                  │  play_track()  pause()      │  │
│               │                  │  resume()      stop()       │  │
│               │                  │  seek()        set_volume() │  │
│               │                  └─────────────┬──────────────┘  │
│               │                                │                 │
│               │                  ┌─────────────▼──────────────┐  │
│               │                  │  app_handle.emit()          │  │
│               │                  │                             │  │
│               │                  │  "shum:state-changed"       │  │
│               │                  │  "shum:position-tick" (2Hz) │  │
│               │                  └─────────────┬──────────────┘  │
└───────────────┼────────────────────────────────┼─────────────────┘
                │                                │
     ┌──────────▼──────────┐          ┌──────────▼───────────────┐
     │  AVAudioEngine       │          │  Tauri IPC Bridge        │
     │  (native playback)   │          │  (JSON over WebView)     │
     └─────────────────────┘          └──────────┬───────────────┘
                                                 │
┌────────────────────────────────────────────────┼──────────────────┐
│              Ripple-TS Frontend (src/)         │                  │
│                                                │                  │
│  ┌─────────────────────────────────────────────▼──────────────┐   │
│  │  App.tsrx                                                   │   │
│  │  listen("shum:state-changed", e => state.applyState(e))    │   │
│  │  listen("shum:position-tick",  e => state.progress = ...)  │   │
│  └──────────────┬──────────────────────────────────────────────┘   │
│                 │                                                   │
│  ┌──────────────▼────────────────┐      ┌────────────────────────┐ │
│  │  state.ts                     │      │  actions.ts            │ │
│  │                               │      │                        │ │
│  │  track<TrackMeta|null>(null)  │      │  requestPlay() ───┐    │ │
│  │  track<PlaybackState>         │      │  requestPause() ───┤   │ │
│  │  track<number>  (derived)     │      │  requestStop() ────┤   │ │
│  │                               │      │  requestSeek() ────┤   │ │
│  │  applyState() is the ONLY     │      │  requestSetVol() ──┤   │ │
│  │  function that calls .set()   │      │         invoke() ◄─┘   │ │
│  └───────────────────────────────┘      └──────────┬─────────────┘ │
│                                                    │               │
│  ┌─────────────────────────────────────────────────▼────────────┐  │
│  │  components/*.tsrx         Pure render functions             │  │
│  │                                                              │  │
│  │  Header              NowPlaying          ProgressBar         │  │
│  │  TransportControls   VolumeControl       StatusBar           │  │
│  │  EmptyState                                                 │  │
│  │                                                              │  │
│  │  Import from:  actions.ts  (for user events → Rust)         │  │
│  │  Receive:      Tracked<T> via &{} lazy destructuring        │  │
│  │  Never import: invoke(), listen(), or @tauri-apps/api        │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

### The three layers

| Layer            | File(s)             | Responsibility                                                                                                    | Writes to              |
| ---------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------- | ---------------------- |
| **IPC Boundary** | `actions.ts`        | Every `invoke()` call lives here. Components request actions; this module talks to Rust.                          | Rust commands          |
| **State Mirror** | `state.ts`          | Read-only `Tracked<T>` values, updated exclusively by Tauri event callbacks. `applyState()` is the single writer. | Nothing (mirrors only) |
| **Render**       | `components/*.tsrx` | Pure functions. Receive state via props, render DOM. User clicks call `actions.*`.                                | Nothing                |

No component ever imports `invoke` or `listen` directly. No component ever calls `.set()` on a `Tracked` value. The separation is enforced by convention and validated by the import graph.

---

## Why Rust Owns All State

| Concern                    | If state lived in JavaScript                                                | With Rust state                                                                                          |
| -------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **iOS background audio**   | WKWebView JS timers are suspended by iOS. Playback stops silently.          | Rust `std::thread` runs on the native process, immune to WebView throttling.                             |
| **Memory pressure**        | iOS may kill the WebView, losing all JS state.                              | `Arc<Mutex<AudioState>>` lives in the native binary. The WebView reconnects to existing state on reload. |
| **Single source of truth** | State split across JS and native creates stale mirrors and race conditions. | Rust is authoritative. JS holds a read-only rendering mirror, updated by push events.                    |
| **Thread safety**          | JavaScript is single-threaded by design.                                    | `Mutex` guards the shared state. The position ticker thread and IPC thread cannot race.                  |
| **Audio latency**          | JS → bridge → native adds a frame of latency.                               | Commands execute directly on the native thread.                                                          |

---

## Tech Stack

| Layer         | Technology                                        | Role                                                     |
| ------------- | ------------------------------------------------- | -------------------------------------------------------- |
| Audio Engine  | Rust + `AVAudioEngine` (iOS)                      | Decode, buffer, and play audio streams                   |
| State Machine | `Arc<Mutex<AudioState>>`                          | Authoritative playback state                             |
| IPC           | Tauri v2 (`#[tauri::command]` + `Emitter`)        | Type-safe Rust ↔ JavaScript communication                |
| UI Framework  | [Ripple-TS](https://www.ripple-ts.com/) (`.tsrx`) | Declarative reactive rendering with fine-grained updates |
| Styling       | Scoped CSS + `oklch()` semantic tokens            | Brutalist aesthetic, single-source theming               |
| Bundler       | Vite + `@ripple-ts/vite-plugin`                   | HMR in development, tree-shaken production builds        |

---

## Project Structure

```
shum/
├── index.html                         # Entry HTML, mounts #root
├── package.json                       # Ripple-TS deps + @tauri-apps/api
├── tsconfig.json                      # Strict TS, jsxImportSource: "ripple"
├── vite.config.ts                     # ripple() plugin, port 5173
│
├── src/
│   ├── index.ts                       # mount(App, { target }) — app bootstrap
│   ├── App.tsrx                       # Root component: Tauri listeners,
│   │                                  #   global CSS tokens, composes children
│   ├── types.ts                       # TypeScript mirrors of Rust Serde types
│   │                                  #   TrackMeta, AudioState, PlaybackState
│   ├── state.ts                       # initState() factory: Tracked<T> mirrors
│   │                                  #   + applyState() sync from Rust events
│   ├── actions.ts                     # Single IPC boundary: all invoke() calls
│   │
│   └── components/
│       ├── Header.tsrx                # SHUM wordmark + "Шум" subtitle
│       ├── EmptyState.tsrx            # Dashed-border empty view
│       ├── NowPlaying.tsrx            # Album art, marquee title, artist/album
│       ├── ProgressBar.tsrx           # Seek bar track/fill + time labels
│       ├── TransportControls.tsrx     # Play/pause/stop buttons
│       ├── VolumeControl.tsrx         # Volume display bar + stop button
│       └── StatusBar.tsrx             # State label + animated status dot
│
└── src-tauri/
    ├── Cargo.toml                     # tauri 2, serde, tauri-plugin-shell
    ├── build.rs                       # tauri_build::build()
    ├── tauri.conf.json                # iOS bundle id, UIBackgroundModes: [audio]
    │
    └── src/
        ├── audio.rs                   # AudioPlatform trait, AudioManager<P>,
        │                              #   PlaybackState enum, TrackMeta struct
        └── lib.rs                     # Tauri v2 commands, NativeAudio stub,
                                       #   state management, position ticker
```

---

## Data Flow

### 1. Frontend → Rust (User Actions)

Components call functions on `actions.ts`. That is the **only** module that imports and calls `invoke()`.

```ts
// src/actions.ts
import { invoke } from "@tauri-apps/api/core";
import type { TrackMeta } from "./types";

export const actions = {
  requestPause() {
    return invoke("pause");
  },

  requestPlay(track: TrackMeta | null) {
    if (track) return invoke("resume");
    return invoke("playTrack", {
      id: "default",
      title: "Test Tone",
      artist: "SHUM",
      album: "System",
      durationSecs: 180,
      coverArtUrl: null,
      streamUrl: "https://example.com/tone.mp3",
    });
  },

  requestStop() {
    return invoke("stop");
  },
  requestSeek(pos: number) {
    return invoke("seek", { positionSecs: pos });
  },
  requestSetVolume(v: number) {
    return invoke("setVolume", { volume: v });
  },
};
```

```tsx
// src/components/TransportControls.tsrx
import { actions } from '../actions';

<button onClick={() => actions.requestPause()}>■</button>
<button onClick={() => actions.requestPlay(track)}>▶</button>
```

### 2. Rust → Frontend (State Sync)

Every command handler in Rust emits an event with the authoritative `AudioState`:

```rust
// src-tauri/src/lib.rs
#[tauri::command]
fn pause(
    state: State<'_, Arc<Mutex<AudioManagerType>>>,
    app_handle: AppHandle,
) -> Result<AudioState, String> {
    let manager = state.inner().lock().map_err(|e| e.to_string())?;
    let result = AudioManagerType::pause(&manager.state(), &manager.platform())?;
    let _ = app_handle.emit("shum:state-changed", &result);
    Ok(result)
}
```

A dedicated background thread emits position ticks at 2Hz:

```rust
std::thread::spawn(move || {
    loop {
        std::thread::sleep(Duration::from_millis(500));
        let result = AudioManagerType::tick_position(/* ... */);
        let _ = handle.emit("shum:position-tick", &audio_state);
    }
});
```

### 3. Mirror Updates (Rendering State)

`App.tsrx` listens for Rust events and routes them to `state.applyState()` — the **only** function that writes to `Tracked<T>` values:

```ts
// src/App.tsrx
listen<AudioState>("shum:state-changed", (e) => s.applyState(e.payload));
```

```ts
// src/state.ts
function applyState(s: AudioState): void {
  if (s.currentTrack !== undefined) _track.set(s.currentTrack);
  if (s.playbackState) _playback.set(s.playbackState);
  if (s.volume !== undefined) _volume.set(s.volume);
  if (s.positionSecs !== undefined) _progress.set(s.positionSecs);
  if (s.currentTrack?.durationSecs) _duration.set(s.currentTrack.durationSecs);
}
```

Components receive these `Tracked<T>` values via `&{}` lazy destructuring, which preserves reactivity across component boundaries:

```tsx
// src/components/NowPlaying.tsrx
export function NowPlaying(&{ track, playbackState }: {
  track: Tracked<TrackMeta | null>;
  playbackState: Tracked<PlaybackState>;
}) {
  return <>
    <span class="track-title" data-state={playbackState}>
      {track?.title ?? '—'}
    </span>
  </>;
}
```

### Summary: What writes where

```
User tap
  │
  ▼
actions.requestPause()         ← only invoke() caller
  │
  ▼
Rust pause() command           ← mutates Arc<Mutex<AudioState>>
  │
  ▼
app_handle.emit("state-changed")
  │
  ▼
listen() callback              ← App.tsrx
  │
  ▼
state.applyState()             ← only .set() caller on Tracked<T>
  │
  ▼
Ripple re-renders              ← components read Tracked<T> via &{}
```

---

## Color Token System

All colors derive from three primitives and a neutral set. Change the three `--pr-*` values in `App.tsrx` to recolor the entire application.

### Primitive Tokens

| Token             | Hex       | `oklch()`             | Role                  |
| ----------------- | --------- | --------------------- | --------------------- |
| `--pr-yellow`     | `#FFDA29` | `oklch(89% 0.21 100)` | Raw brand color       |
| `--pr-gentian`    | `#3366FF` | `oklch(52% 0.32 262)` | Raw accent color      |
| `--pr-ruby`       | `#F10C45` | `oklch(53% 0.28 12)`  | Raw danger/stop color |
| `--pr-ink`        | —         | `oklch(12% 0.02 260)` | Deepest background    |
| `--pr-ink-raised` | —         | `oklch(16% 0.02 260)` | Elevated surfaces     |
| `--pr-white`      | —         | `oklch(98% 0 0)`      | Pure white            |

### Semantic Tokens

Each primitive is assigned a **role** via a semantic alias. Components never reference primitives directly — they use the role tokens.

| Token                      | Maps to                                            | Used for                                                     |
| -------------------------- | -------------------------------------------------- | ------------------------------------------------------------ |
| `--color-primary`          | `--pr-yellow`                                      | Borders, highlights, progress fill, shadows, pause indicator |
| `--color-secondary`        | `--pr-gentian`                                     | Accent borders, playing indicator, artist name, volume fill  |
| `--color-tertiary`         | `--pr-ruby`                                        | Stop button, buffering indicator, error states               |
| `--color-surface`          | `--pr-ink`                                         | Page background, button background                           |
| `--color-surface-elevated` | `--pr-ink-raised`                                  | Now Playing panel, primary buttons                           |
| `--color-text`             | `--pr-white`                                       | Primary text everywhere                                      |
| `--color-text-muted`       | `oklch(98% 0 0 / 0.45)`                            | Secondary labels, album name, time total                     |
| `--border-width`           | `3px`                                              | All structural borders                                       |
| `--shadow-offset`          | `4px`                                              | Neo-brutalist box-shadow offset                              |
| `--font-family`            | `'SF Mono', 'Fira Code', 'Courier New', monospace` | Global typography                                            |

### How to Re-skin

Change these three lines in `src/App.tsrx` — every component follows:

```css
--pr-yellow: oklch(89% 0.21 100); /* primary */
--pr-gentian: oklch(52% 0.32 262); /* secondary */
--pr-ruby: oklch(53% 0.28 12); /* tertiary */
```

### Token Assignment Logic

| UI Element          | Uses                | Reason                             |
| ------------------- | ------------------- | ---------------------------------- |
| Progress bar fill   | `--color-primary`   | Dominant, attention-grabbing       |
| Marquee title       | `--color-primary`   | Most important text                |
| Now Playing border  | `--color-primary`   | Structural anchor                  |
| Play button shadow  | `--color-primary`   | Primary CTA reinforcement          |
| Playing state dot   | `--color-secondary` | Calm, steady "active" signifier    |
| Artist name         | `--color-secondary` | Secondary information              |
| Album art border    | `--color-secondary` | Visual frame, not main focus       |
| Stop button         | `--color-tertiary`  | Destructive/terminal action        |
| Buffering indicator | `--color-tertiary`  | Transient, alerting state          |
| Header char-a       | `--color-tertiary`  | First letter — bold opener         |
| Header char-b       | `--color-primary`   | Second letter — brand anchor       |
| Header char-c       | `--color-secondary` | Third letter — complementary close |

---

## Getting Started

### Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) (stable)
- [Node.js](https://nodejs.org/) ≥ 22
- [Xcode](https://developer.apple.com/xcode/) 16+ (for iOS builds)
- iOS 16+ device or simulator

### Install

```bash
npm install
```

### Development (Web Preview)

```bash
npm run dev
```

Opens at `http://localhost:5173`. Useful for layout and styling iteration.

### Development (iOS Simulator)

```bash
cargo tauri ios dev
```

Builds the Rust library for `aarch64-apple-ios-sim`, launches the app in the iOS Simulator.

### Development (Physical Device)

```bash
cargo tauri ios dev --host
```

### Production Build

```bash
cargo tauri ios build
```

Produces an `.ipa` in `src-tauri/gen/apple/build/`.

### Type Check

```bash
npm run typecheck
```

Runs `tsrx-tsc --noEmit` to validate all `.tsrx` and `.ts` files against the strict TypeScript configuration.

---

## iOS Deployment

1. Open `src-tauri/tauri.conf.json` and set `bundle.iOS.developmentTeam` to your Apple Developer Team ID.
2. Open the generated Xcode project at `src-tauri/gen/apple/`.
3. In Xcode → Signing & Capabilities:
   - Select your team.
   - Add the **Background Modes** capability and check **Audio, AirPlay, and Picture in Picture**.
4. Build and archive via Xcode or `cargo tauri ios build`.

The `infoPlist` in `tauri.conf.json` already declares `UIBackgroundModes: ["audio"]`. The Xcode capability step confirms it in the provisioning profile.

---

## Architecture Decisions

| Decision                                    | Rationale                                                                                                                                                 |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Rust state, not JS state**                | iOS kills WKWebView JS timers in the background. Rust threads persist.                                                                                    |
| **`Arc<Mutex<>>` not `Arc<RwLock<>>`**      | Audio state mutations are short-lived (set a field, emit an event). `Mutex` has lower overhead and avoids reader starvation from the 2Hz position ticker. |
| **Tauri events, not polling**               | Push-based sync avoids wasted IPC cycles. Position ticks are the only recurring event (2Hz, lightweight).                                                 |
| **`.tsrx` components from Ripple-TS**       | Ripple-TS (by `@trueadm`) is a modern fine-grained reactivity framework. The older `ripplejs/ripple` is a different library with a different API.         |
| **`actions.ts` as single IPC boundary**     | Isolates every `invoke()` call to one file. Makes testing, mocking, and auditing trivial. Components never import Tauri APIs directly.                    |
| **`&{}` lazy prop destructuring**           | Preserves reactivity across component boundaries. Child components re-render when the parent's `Tracked<T>` changes, without `.value` boilerplate.        |
| **Semantic CSS tokens in `:global(:root)`** | Define colors once, use everywhere via `var()`. To reskin the app, change 3 hex values in `App.tsrx`.                                                     |
| **Concrete `AudioPlatform` trait**          | `NativeAudio` is a stub. Swap in a real `AVAudioEngineAudio` implementation without touching `AudioManager<P>` or any command handler.                    |
| **Position ticker on dedicated thread**     | Decouples UI polling from audio playback. The ticker runs at 500ms intervals independent of the WebView's render cycle.                                   |

---

## License

MIT
