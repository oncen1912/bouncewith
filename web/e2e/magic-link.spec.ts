import { expect, test } from '@playwright/test'

// Local only: reads the e-mail from Mailpit (started by `npx supabase start`).
const mailpit = process.env.MAILPIT_URL ?? 'http://127.0.0.1:54324'
test.skip(!!process.env.BASE_URL, 'needs the local Supabase mail catcher')

test('magic link signs the user in and returns to the requested page', async ({ page, request }, info) => {
  test.skip(info.project.name !== 'desktop', 'one run is enough')
  const email = 'luka@niko-dance.example'
  await request.delete(`${mailpit}/api/v1/search?query=${encodeURIComponent(`to:${email}`)}`)

  await page.goto('/me')
  await page.getByRole('textbox', { name: 'E-mail' }).fill(email)
  await page.getByRole('button', { name: 'Send me a sign-in link' }).click()
  await expect(page.getByRole('status')).toContainText(email)

  let link: string | undefined
  await expect
    .poll(async () => {
      const res = await request.get(`${mailpit}/api/v1/search?query=${encodeURIComponent(`to:${email}`)}`)
      const { messages } = (await res.json()) as { messages: { ID: string }[] }
      if (!messages[0]) return undefined
      const msg = await (await request.get(`${mailpit}/api/v1/message/${messages[0].ID}`)).json()
      link = (msg.Text as string).match(/https?:\/\/\S+/)?.[0]
      return link
    })
    .toBeTruthy()

  await page.goto(link!)
  await expect(page).toHaveURL(/\/me$/)
  await expect(page.getByText(email)).toBeVisible()
})
