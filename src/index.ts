import { mount } from "ripple";
// @ts-expect-error known issue with .tsrx imports
import { App } from "./App.tsrx";

const root = document.getElementById("root");
if (!root) {
  document.body.innerHTML =
    '<h1 style="font-family:sans-serif;color:#f10c45;text-align:center;padding-top:40vh">ROOT NOT FOUND</h1>';
} else {
  try {
    mount(App, { target: root });
  } catch (e) {
    root.innerHTML = `<h1 style="font-family:sans-serif;color:#f10c45;text-align:center;padding-top:40vh">MOUNT ERROR: ${String(e).slice(0, 120)}</h1>`;
  }
}
