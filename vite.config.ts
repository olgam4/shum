import { defineConfig } from 'vite';
import { ripple } from '@ripple-ts/vite-plugin';

export default defineConfig({
  plugins: [ripple()],
  server: {
    port: 5173,
    strictPort: true,
  },
  build: {
    target: 'safari16',
    minify: 'terser',
    sourcemap: false,
  },
});
