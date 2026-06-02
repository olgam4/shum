import { invoke } from "@tauri-apps/api/core";
import { Context, track, type Tracked } from "ripple";
import type { SearchResult, SyncResult } from "../types";

const libraryCtx = new Context<{
  data: Tracked<SearchResult>;
  artistCount: Tracked<number>;
  albumCount: Tracked<number>;
  songCount: Tracked<number>;
  lastSync: Tracked<string | null>;
  syncing: Tracked<boolean>;
}>({} as never);

let _object: ReturnType<typeof libraryCtx.get>;

export function initLibrary() {
  _object = libraryCtx.get();
  _object.data = track<SearchResult>({ artists: [], albums: [], songs: [] });
  _object.artistCount = track(0);
  _object.albumCount = track(0);
  _object.songCount = track(0);
  _object.lastSync = track<string | null>(null);
  _object.syncing = track(false);
}

export const library = {
  get state() {
    return _object;
  },
};

export function syncLibrary(): Promise<SyncResult> {
  return invoke("sync_library");
}

export function searchLibrary(query: string): Promise<SearchResult> {
  return invoke("search_library", { query });
}
