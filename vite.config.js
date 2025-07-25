import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  preview: {
    allowedHosts: [
      'statslife.omont.ch'
    ]
  },
  server: {
    host: true, // Needed for proper network access
    port: 5173, // Default Vite port
  }
})