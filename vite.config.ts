import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'

const base = process.env.VITE_BASE_PATH || '/'

export default defineConfig({
  base,
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['app-icon.svg', 'app-icon-180.png', 'app-icon-512.png'],
      manifest: {
        name: '定时提醒',
        short_name: '提醒',
        description: '为任意未来日期和时间创建提醒',
        theme_color: '#ff9500',
        background_color: '#f5f5f7',
        display: 'standalone',
        orientation: 'portrait',
        lang: 'zh-CN',
        start_url: base,
        scope: base,
        icons: [
          {
            src: `${base}app-icon-512.png`,
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any',
          },
          {
            src: `${base}app-icon-512.png`,
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png}'],
      },
    }),
  ],
})
