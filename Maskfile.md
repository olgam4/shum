# SHUM — DevOps Commands

> All commands from `/Users/alysondube/shum`
>
> Run with: `mask <command>` (e.g. `mask dev`)

## init

```mask
## deps.frontend
bun install

## deps.esbuild (required for Vite v8 production builds)
bun add -d esbuild

## src-tauri/tauri.conf.json
### @bundle.iOS.developmentTeam
YOUR_TEAM_ID

## First-time setup (one-time per machine)
- Install Xcode from App Store, open once to accept license
- sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
- brew install cocoapods
- rustup target add aarch64-apple-ios aarch64-apple-ios-sim
- cargo install tauri-cli
```

---

## dev

```mask
## Start the Vite + Ripple-TS frontend (web only, no native)
bun run dev
```

## dev-ios

```mask
## Build + run on iOS Simulator with hot reload
## Requires: bun run dev running in a separate terminal (Terminal 1)
##
## Terminal 1: bun run dev            (Vite dev server on :5173)
## Terminal 2: cargo tauri ios dev    (pick iPhone 17 Pro)
```

## dev-ios-pro

```mask
## Build + run on iPhone 17 Pro (non-interactive, hot reload)
## Needs bun run dev running separately
cargo tauri ios dev --device "iPhone 17 Pro"
```

## dev-ios-host

```mask
## Build + deploy to physical iPhone via USB
## Requires: Apple Developer Team ID in tauri.conf.json
bun run build && cargo tauri ios dev --host
```

---

## build

```mask
## Build frontend to dist/
bun run build
```

## build-ios

```mask
## One-shot build + install on simulator (no hot reload)
## Uses pre-built dist/ — no dev server needed
bun run build && cargo tauri ios build --debug
```

## build-rust

```mask
## Check Rust compilation (fast, no linking)
cd src-tauri && cargo check
```

## build-rust-release

```mask
## Build Rust in release mode
cd src-tauri && cargo build --release
```

---

## check

```mask
## TypeScript type-check
bun run typecheck

## Clippy lint
cd src-tauri && cargo clippy -- -D warnings

## Rust check (fast)
cd src-tauri && cargo check

## Format check
bun run format:check
```

## fix

```mask
## Auto-fix formatting
bun run format

## Auto-fix Rust lints
cd src-tauri && cargo clippy --fix --allow-dirty --allow-staged
```

---

## clean

```mask
## Full clean (frontend + Rust)
rm -rf dist/
cd src-tauri && cargo clean
```

## clean-ios

```mask
## Remove Xcode project + regenerate from scratch
rm -rf src-tauri/gen/apple/
cargo tauri ios init
```

---

## xcode

```mask
## Open the Xcode project (auto-detects sim or device target)
open src-tauri/gen/apple/ios-sim-*/SHUM.xcodeproj 2>/dev/null
open src-tauri/gen/apple/ios-*/SHUM.xcodeproj 2>/dev/null
```

## sim

```mask
## List available iPhone simulators
xcrun simctl list devices available | grep -v "unavailable" | grep iPhone

## Boot a specific simulator
xcrun simctl boot "iPhone 17 Pro"

## Shutdown all simulators
xcrun simctl shutdown all

## Open Simulator.app
open -a Simulator

## Reset a simulator (factory erase)
xcrun simctl erase "iPhone 17 Pro"
```

---

## logs

```mask
## Stream all logs from the SHUM app on simulator
xcrun simctl spawn booted log stream --predicate 'processImagePath CONTAINS "shum"' --style compact

## Stream only Rust logs (subsystem contains "shum")
xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "sh.anomaly.shum"' --style compact

## Show recent logs from SHUM
xcrun simctl spawn booted log show --predicate 'processImagePath CONTAINS "shum"' --last 5m --style compact

## Show ALL system logs from the booted simulator (broad, use with grep)
xcrun simctl spawn booted log stream --style compact 2>&1 | grep -i shum
```

---

## deps

```mask
## Install / update frontend dependencies
bun install

## Ensure esbuild is installed (required for Vite v8 builds)
bun add -d esbuild

## Rust dependencies (auto-resolved on build)

## Install Tauri CLI (one-time)
cargo install tauri-cli

## Add iOS Rust targets (one-time)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
```

## info

```mask
## System tooling audit
xcrun xcodebuild -version
rustup show active-toolchain
cargo --version
bun --version
xcrun simctl list devices available | head -10
system_profiler SPDeveloperToolsDataType | grep -A2 "Xcode:"
```

---

## quick

```mask
## Full dev cycle into simulator (one-shot, no hot reload)
cd src-tauri && cargo check && cd ..
bun run build
cargo tauri ios build --debug
```
