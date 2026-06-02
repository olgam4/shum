import { defineConfig } from "vite";
import { ripple } from "@ripple-ts/vite-plugin";

const host = process.env.TAURI_DEV_HOST;

export default defineConfig({
  plugins: [ripple()],
  clearScreen: false,
  server: {
    port: 5173,
    strictPort: true,
    host: host || "localhost",
    hmr: host ? { protocol: "ws", host, port: 5173 } : undefined,
    watch: { ignored: ["**/src-tauri/**"] },
  },
  envPrefix: ["VITE_", "TAURI_ENV_"],
  build: {
    target:
      process.env.TAURI_ENV_PLATFORM === "windows" ? "chrome105" : "safari16",
    minify: !process.env.TAURI_ENV_DEBUG ? "esbuild" : false,
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
  },
});
