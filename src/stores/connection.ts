import { invoke } from "@tauri-apps/api/core";
import { Context, track, type Tracked } from "ripple";
import type { ConnectionInfo, ConnectionStatus, StartupState } from "../types";

const connectionCtx = new Context<{
  status: Tracked<ConnectionStatus>;
  info: Tracked<ConnectionInfo>;
}>({} as never);

let _object: ReturnType<typeof connectionCtx.get>;

export function initConnection() {
  _object = connectionCtx.get();
  _object.status = track<ConnectionStatus>("disconnected");
  _object.info = track<ConnectionInfo>({ connected: false });
}

export const connection = {
  get status() {
    return _object.status;
  },
  get info() {
    return _object.info;
  },
};

export async function connectServer(
  url: string,
  username: string,
  password: string,
): Promise<ConnectionInfo> {
  return invoke("connect_server", { serverUrl: url, username, password });
}

export function disconnect(): Promise<void> {
  return invoke("disconnect");
}

export function startupHydrate(): Promise<StartupState> {
  return invoke("startup_hydrate");
}
