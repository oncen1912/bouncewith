import { expect, test, type Page } from '@playwright/test'

// M1 done-when: a second user joins by QR (the QR encodes /join/:code), is approved, and only sees that workspace.
// Local only: it signs up new users, which must not happen against production.
test.skip(!!process.env.BASE_URL, 'creates users; local Supabase only')

async function signInWithPassword(page: Page, email: string, password: string, signUp = false) {
  await page.getByText('Password', { exact: true }).click()
  if (signUp) {
    await page.getByRole('button', { name: 'No account yet? Create one' }).click()
    await page.getByLabel('Full name').fill('Eve Example')
  }
  await page.getByRole('textbox', { name: 'E-mail' }).fill(email)
  await page.locator('input[type=password]').fill(password)
  await page.getByRole('button', { name: signUp ? 'Create account' : 'Sign in' }).click()
}

test('a new user joins by invite link, gets approved and sees only that workspace', async ({
  browser,
}, info) => {
  test.skip(info.project.name !== 'desktop', 'one run is enough')
  const email = `eve-${Date.now()}@e2e.example`

  // the owner's invite QR points at /join/<code>
  const owner = await browser.newPage()
  await owner.goto('/w/niko-dance/settings')
  await signInWithPassword(owner, 'owner@niko-dance.example', 'bouncewith')
  await expect(owner.getByRole('img', { name: 'QR code with the invite link' })).toBeVisible()
  const code = (await owner.getByTestId('join-code').textContent())!.trim()
  expect(code).toMatch(/^[A-Z0-9]{8}$/)

  // new user opens the link, signs up, asks to join
  const eve = await browser.newPage()
  await eve.goto(`/join/${code}`)
  await signInWithPassword(eve, email, 'correct-horse-42', true)
  await expect(eve.getByRole('heading', { name: 'Niko Dance School' })).toBeVisible()
  await eve.getByRole('button', { name: 'Join Niko Dance School' }).click()
  await expect(eve.getByText('Your request was sent')).toBeVisible()
  await eve.goto('/w/niko-dance')
  await expect(eve.getByText('Waiting for approval at Niko Dance School')).toBeVisible()

  // trainer approves
  const trainer = await browser.newPage()
  await trainer.goto('/w/niko-dance/members')
  await signInWithPassword(trainer, 'trainer@niko-dance.example', 'bouncewith')
  const request = trainer.getByRole('listitem').filter({ hasText: email })
  await request.getByRole('button', { name: 'Approve' }).click()
  await expect(trainer.getByText('Eve Example is now a member')).toBeVisible()

  // Eve now has exactly one workspace
  await eve.goto('/w')
  const cards = eve.getByRole('main').getByRole('link', { name: /Member$/ })
  await expect(cards).toHaveCount(1)
  await expect(cards.first()).toContainText('Niko Dance School')
  await cards.first().click()
  await expect(eve.getByRole('heading', { name: 'Hi Eve!' })).toBeVisible()
  await eve.goto('/w/yoga-zug')
  await expect(eve.getByText('Workspace not found')).toBeVisible()
})

test('members cannot open trainer screens', async ({ page }, info) => {
  test.skip(info.project.name !== 'desktop', 'one run is enough')
  await page.goto('/w/niko-dance/members')
  await signInWithPassword(page, 'mia@niko-dance.example', 'bouncewith')
  await expect(page).toHaveURL(/\/w\/niko-dance$/)
  await expect(
    page.getByRole('navigation', { name: 'Main navigation' }).getByRole('link', { name: 'Members' }),
  ).toHaveCount(0)
})
