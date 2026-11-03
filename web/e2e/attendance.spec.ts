import { expect, test, type Page } from '@playwright/test'

// M3. Local only: uses the seeded zug-crew class of 15 (12 going, 1 can't, 2 no answer).
test.skip(!!process.env.BASE_URL, 'changes data; local Supabase only')
// the tests share the class of 15: run them one after another so answers don't change mid-check-in
test.describe.configure({ mode: 'serial' })

async function signIn(page: Page, email: string) {
  await page.getByText('Password', { exact: true }).click()
  await page.getByRole('textbox', { name: 'E-mail' }).fill(email)
  await page.locator('input[type=password]').fill('bouncewith')
  await page.getByRole('button', { name: 'Sign in' }).click()
}

const CHECKIN = '/w/zug-crew/events/c2000000-0000-0000-0000-000000000001/checkin'

test('a member answers from the home screen', async ({ page }, info) => {
  test.skip(info.project.name !== 'phone', 'phone-first')
  await page.goto('/w/zug-crew')
  await signIn(page, 'dancer14@zug-crew.example')
  const card = page.getByRole('article').filter({ hasText: 'Crew Practice' })
  await card.getByRole('button', { name: "Can't make it" }).click()
  await page.getByLabel('Reason (optional)').fill('Dentist')
  await page.getByRole('dialog').getByRole('button', { name: 'Send' }).click()
  await expect(page.getByText('Thanks for letting us know')).toBeVisible()
  await expect(card.getByRole('button', { name: "Can't make it" })).toHaveAttribute('aria-pressed', 'true')
  await card.getByRole('button', { name: "I'm in" }).click()
  await expect(page.getByText('See you there!')).toBeVisible()
  await expect(card.getByRole('button', { name: "I'm in" })).toHaveAttribute('aria-pressed', 'true')
  // back to "no answer" for the check-in test is not possible by design; switch to "can't" again
  await card.getByRole('button', { name: "Can't make it" }).click()
  await page.getByRole('dialog').getByRole('button', { name: 'Send' }).click()
  await expect(card.getByRole('button', { name: "Can't make it" })).toHaveAttribute('aria-pressed', 'true')
})

test('done-when: a trainer checks in a class of 15 on a phone in under 30 seconds', async ({
  browser,
}, info) => {
  test.skip(info.project.name !== 'phone', 'phone-first')
  const page = await browser.newPage({
    viewport: { width: 375, height: 812 },
    isMobile: true,
    hasTouch: true,
  })
  await page.goto(CHECKIN)
  await signIn(page, 'coach@zug-crew.example')
  const count = page.locator('.bw-checkin-count strong')
  await expect(count).toBeVisible()

  // a previous run may have left marks: start from a clean slate
  if ((await count.textContent())?.trim() !== '12') {
    await page.getByRole('button', { name: 'Reset' }).click()
    await page.getByLabel(/Type the event title/).fill('Crew Practice')
    await page.getByRole('dialog').getByRole('button', { name: 'Reset' }).click()
    await expect(count).toHaveText('0')
    await page.getByRole('button', { name: 'Start check-in' }).click()
  }

  const started = Date.now()
  await expect(count).toHaveText('12') // confirmed members are present by default
  await page.getByRole('button', { name: /Ana Kos/ }).click() // absent
  await page.getByRole('button', { name: /Bine Vidmar/ }).click() // absent
  await page.getByRole('button', { name: /Ola Bergant/ }).click() // came without answering
  await expect(count).toHaveText('11')
  expect(Date.now() - started).toBeLessThan(30_000)

  await page.reload() // marks are saved, not just shown
  await expect(count).toHaveText('11')
  await expect(page.getByRole('button', { name: /Ana Kos/ })).toContainText('Absent')

  // QR self check-in by a member who answered "can't make it"
  const tokenResponse = page.waitForResponse((r) => r.url().includes('/rpc/create_checkin_token'))
  await page.getByRole('button', { name: 'Show QR' }).click()
  await expect(page.getByRole('img', { name: 'QR code for self check-in' })).toBeVisible()
  const token = (await (await tokenResponse).json()) as string
  const member = await browser.newPage()
  await member.goto(`/checkin/${token}`)
  await signIn(member, 'dancer13@zug-crew.example')
  await expect(member.getByText("You're checked in")).toBeVisible()
  await page.getByRole('dialog').getByRole('button', { name: 'Close' }).first().click()
  await page.reload()
  await expect(count).toHaveText('12')

  // reset only this event (typed confirmation)
  await page.getByRole('button', { name: 'Reset' }).click()
  const confirm = page.getByRole('dialog').getByRole('button', { name: 'Reset' })
  await expect(confirm).toBeDisabled()
  await page.getByLabel(/Type the event title/).fill('Crew Practice')
  await confirm.click()
  // 12 confirmed + 1 walk-in + 1 QR check-in
  await expect(page.getByText('Attendance reset: 14 removed')).toBeVisible()
  await expect(count).toHaveText('0')
  // a reset sticks: reopening doesn't pre-tick again; the trainer restarts on purpose
  await page.reload()
  await expect(count).toHaveText('0')
  await page.getByRole('button', { name: 'Start check-in' }).click()
  await expect(count).not.toHaveText('0')
})

test('members cannot open the check-in screen', async ({ page }, info) => {
  test.skip(info.project.name !== 'desktop', 'one run is enough')
  await page.goto(CHECKIN)
  await signIn(page, 'dancer01@zug-crew.example')
  await expect(page).toHaveURL(/\/w\/zug-crew$/)
})
