import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Builds a single self-registering dist/widget.js (SPEC §8.2). Components ending in .ce.vue get Shadow DOM styles.
export default defineConfig({
  plugins: [vue({ features: { customElement: true } })],
  define: { 'process.env.NODE_ENV': JSON.stringify('production') },
  build: {
    lib: { entry: 'src/main.ts', formats: ['iife'], name: 'BounceWith', fileName: () => 'widget.js' },
  },
})
