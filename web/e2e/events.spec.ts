import { expect, test, type Page } from '@playwright/test'

// M2: a trainer creates a weekly series in the form; it is planned 12 weeks ahead at the same local time.
test.skip(!!process.env.BASE_URL, 'creates data; local Supabase only')

async function signIn(page: Page, email: string) {
  await page.getByText('Password', { exact: true }).click()
  await page.getByRole('textbox', { name: 'E-mail' }).fill(email)
  await page.locator('input[type=password]').fill('bouncewith')
  await page.getByRole('button', { name: 'Sign in' }).click()
}

test('trainer creates a weekly class; members see it; one occurrence is cancelled', async ({
  browser,
}, info) => {
  test.skip(info.project.name !== 'desktop', 'one run is enough')
  const title = `Popping ${Date.now() % 100000}`

  const trainer = await browser.newPage()
  await trainer.goto('/w/niko-dance/events/new')
  await signIn(trainer, 'trainer@niko-dance.example')
  await trainer.getByLabel('Title').fill(title)
  await trainer.getByLabel('Category').fill('workshop')
  await trainer.getByLabel('Description').fill('Waves and hits.\n\nBring indoor shoes.')
  await trainer.getByLabel('Starts').fill('18:30')
  await trainer.getByLabel('Ends').fill('20:00')
  await trainer.getByLabel('Repeats every week').check()
  await trainer.getByLabel('Capacity').fill('20')
  await trainer.getByRole('button', { name: 'Create event' }).click()

  await expect(trainer.getByText(/Series created: 1[23] events planned/)).toBeVisible()
  await expect(trainer.getByRole('heading', { level: 1, name: title })).toBeVisible()
  await expect(trainer.getByText('18:30–20:00')).toBeVisible()
  await expect(trainer.getByText(/Every week on/)).toBeVisible()
  await expect(trainer.getByText('Bring indoor shoes.')).toBeVisible()

  // a member sees all occurrences in the list, each at 18:30 local time
  const member = await browser.newPage()
  await member.goto('/w/niko-dance/events')
  await signIn(member, 'mia@niko-dance.example')
  const cards = member.getByRole('article').filter({ hasText: title })
  await expect(cards.first()).toBeVisible()
  expect(await cards.count()).toBeGreaterThanOrEqual(12)
  for (const card of await cards.all()) await expect(card).toContainText('18:30–20:00')
  await expect(member.getByRole('link', { name: 'New event' })).toHaveCount(0)

  // trainer cancels only the first occurrence, with a notice
  await trainer.getByRole('button', { name: 'Cancel event' }).click()
  await trainer.getByRole('dialog').getByRole('button', { name: 'Cancel event' }).click()
  await expect(trainer.getByText('Cancelled: 1')).toBeVisible()
  await expect(trainer.locator('.bw-hero').getByText('Cancelled')).toBeVisible()

  await member.reload()
  await expect(
    member.getByRole('article').filter({ hasText: title }).filter({ hasText: 'Cancelled' }),
  ).toHaveCount(1)
})

test('week and month views show the seeded weekly classes', async ({ page }, info) => {
  test.skip(info.project.name !== 'desktop', 'one run is enough')
  await page.goto('/w/niko-dance/events?view=week')
  await signIn(page, 'ana@niko-dance.example')
  await expect(page.getByRole('link', { name: /Juniors Training/ }).first()).toBeVisible()
  await page.getByText('Mesec', { exact: true }).click() // Ana uses Slovenian
  await expect(page).toHaveURL(/view=month/)
  await page.getByRole('button', { name: 'Naslednji' }).click()
  await expect(page.locator('.bw-dot').first()).toBeVisible()
})
