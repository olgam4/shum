import { initRouter } from "./router";
import { initConnection } from "./connection";
import { initLibrary } from "./library";
import { initNowPlaying } from "./now-playing";

export function initStores() {
  initRouter();
  initConnection();
  initLibrary();
  initNowPlaying();
}

export { router, navigate, navigateToArtist, navigateToAlbum } from "./router";
export {
  connection,
  connectServer,
  disconnect,
  startupHydrate,
} from "./connection";
export { library, syncLibrary, searchLibrary } from "./library";
export {
  nowPlaying,
  initAudio,
  playSong,
  playUrl,
  playLocal,
  requestPlay,
  requestPause,
  requestStop,
  requestSeek,
  setQueue,
  addToQueue,
  nextInQueue,
  getStreamUrl,
  getCoverArtUrl,
  cacheSong,
  getCachedSongPath,
  haptic,
} from "./now-playing";
