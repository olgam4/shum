import { Context, track, type Tracked } from "ripple";
import type { Route } from "../types";

const routeCtx = new Context<{
  current: Tracked<Route>;
  previous: Tracked<Route>;
  direction: Tracked<"forward" | "back">;
}>({} as never);
const selectedArtistCtx = new Context<{
  id: Tracked<string>;
  name: Tracked<string>;
}>({} as never);
const selectedAlbumCtx = new Context<{
  id: Tracked<string>;
  name: Tracked<string>;
  artistId: Tracked<string>;
  artistName: Tracked<string>;
}>({} as never);

let _routeObj: ReturnType<typeof routeCtx.get>;
let _selectedArtistObj: ReturnType<typeof selectedArtistCtx.get>;
let _selectedAlbumObj: ReturnType<typeof selectedAlbumCtx.get>;

export const ROUTE_DEPTH: Record<Route, number> = {
  home: 0,
  library: 1,
  settings: 2,
  artist: 3,
  album: 3,
};

export const MAIN_TABS: Route[] = ["home", "library", "settings"];

export function initRouter() {
  _routeObj = routeCtx.get();
  _routeObj.current = track<Route>("home");
  _routeObj.previous = track<Route>("home");
  _routeObj.direction = track<"forward" | "back">("forward");

  _selectedArtistObj = selectedArtistCtx.get();
  _selectedArtistObj.id = track("");
  _selectedArtistObj.name = track("");

  _selectedAlbumObj = selectedAlbumCtx.get();
  _selectedAlbumObj.id = track("");
  _selectedAlbumObj.name = track("");
  _selectedAlbumObj.artistId = track("");
  _selectedAlbumObj.artistName = track("");
}

export const router = {
  get state() {
    return _routeObj;
  },
  get selectedArtist() {
    return _selectedArtistObj;
  },
  get selectedAlbum() {
    return _selectedAlbumObj;
  },
};

export function navigateToArtist(id: string, name: string) {
  _selectedArtistObj.id.value = id;
  _selectedArtistObj.name.value = name;
  const prev = _routeObj.current.value;
  _routeObj.previous.value = prev;
  _routeObj.direction.value =
    ROUTE_DEPTH["artist"] > ROUTE_DEPTH[prev] ? "forward" : "back";
  _routeObj.current.value = "artist";
}

export function navigateToAlbum(
  id: string,
  name: string,
  artistId: string,
  artistName: string,
) {
  _selectedAlbumObj.id.value = id;
  _selectedAlbumObj.name.value = name;
  _selectedAlbumObj.artistId.value = artistId;
  _selectedAlbumObj.artistName.value = artistName;
  const prev = _routeObj.current.value;
  _routeObj.previous.value = prev;
  _routeObj.direction.value =
    ROUTE_DEPTH["album"] > ROUTE_DEPTH[prev] ? "forward" : "back";
  _routeObj.current.value = "album";
}

export function navigate(route: Route) {
  const prev = _routeObj.current.value;
  _routeObj.previous.value = prev;
  _routeObj.direction.value =
    ROUTE_DEPTH[route] > ROUTE_DEPTH[prev] ? "forward" : "back";
  _routeObj.current.value = route;
}
