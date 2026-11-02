import { defineConfig, devices } from '@playwright/test'

const baseURL = process.env.BASE_URL ?? 'http://localhost:4173'

export default defineConfig({
  testDir: 'web/e2e',
  fullyParallel: true,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? 'github' : 'list',
  use: { baseURL, trace: 'on-first-retry' },
  projects: [
    { name: 'phone', use: { ...devices['iPhone 13'], browserName: 'chromium' } },
    { name: 'desktop', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: process.env.BASE_URL
    ? undefined
    : { command: 'npm run build -w web && npm run preview -w web', url: baseURL, reuseExistingServer: true },
})
