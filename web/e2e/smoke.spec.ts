import { expect, test } from '@playwright/test'

// Defaults match supabase/seed.sql. Against a deployed URL set E2E_EMAIL / E2E_PASSWORD.
const email = process.env.E2E_EMAIL || 'mia@niko-dance.example'
const password = process.env.E2E_PASSWORD || 'bouncewith'
const workspaceName = process.env.E2E_WORKSPACE_NAME || 'Niko Dance School'

test('protected pages redirect to login and keep the target', async ({ page }) => {
  await page.goto('/me')
  await expect(page).toHaveURL(/\/login\?redirect=(%2F|\/)me$/)
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible()
})

test('a seeded user signs in with a password and sees the home screen', async ({ page, isMobile }) => {
  await page.goto('/login')
  await page.getByText('Password', { exact: true }).click()
  await page.getByRole('textbox', { name: 'E-mail' }).fill(email)
  await page.locator('input[type=password]').fill(password)
  await page.getByRole('button', { name: 'Sign in' }).click()

  await expect(
    page,
    'sign-in did not reach the workspace list (against a deployed URL: check the E2E_EMAIL / E2E_PASSWORD secrets)',
  ).toHaveURL(/\/w$/)
  await page.getByRole('link', { name: new RegExp(workspaceName) }).click()

  await expect(page.getByRole('heading', { name: /^Hi / })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Next events' })).toBeVisible()

  // phones get the bottom tab bar, desktops the sidebar; role queries only see the visible one
  const nav = page.getByRole('navigation', { name: 'Main navigation' })
  await expect(nav).toHaveCount(1)
  await expect(nav.getByRole('link', { name: 'Events' })).toBeVisible()
  if (isMobile) await expect(page.locator('.bw-tabbar')).toBeVisible()
  else await expect(page.locator('.bw-sidebar')).toBeVisible()
})

test('the app has no horizontal scroll at 375 px', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 740 })
  await page.goto('/login')
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)
  expect(overflow).toBeLessThanOrEqual(0)
})
