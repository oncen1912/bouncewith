// Creates (or repairs) a demo workspace with an owner and a member in a Supabase project, so a fresh
// cloud project has someone who can sign in. Idempotent: safe to run again.
//
//   npm run demo:create            # reads .env.cloud (gitignored)
//
// Needs SUPABASE_URL and SUPABASE_SECRET_KEY (sb_secret_…). Runs on your machine only, never in the browser.
// DEMO_PASSWORD is optional; without it a random password is generated and printed once.
import { randomBytes } from 'node:crypto'
import { createClient } from '@supabase/supabase-js'
import type { Database } from '../shared/database.types.ts'

const url = process.env.SUPABASE_URL
const secretKey = process.env.SUPABASE_SECRET_KEY
if (!url || !secretKey?.startsWith('sb_secret_')) {
  console.error('Set SUPABASE_URL and SUPABASE_SECRET_KEY (sb_secret_…) in .env.cloud')
  process.exit(1)
}

const password = process.env.DEMO_PASSWORD ?? randomBytes(12).toString('base64url')
const slug = process.env.DEMO_WORKSPACE_SLUG ?? 'demo'
const users = [
  {
    email: process.env.DEMO_OWNER_EMAIL ?? 'demo-owner@bouncewith.me',
    fullName: 'Demo Owner',
    role: 'owner',
  },
  {
    email: process.env.DEMO_MEMBER_EMAIL ?? 'demo-member@bouncewith.me',
    fullName: 'Demo Member',
    role: 'member',
  },
] as const

const admin = createClient<Database>(url, secretKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

async function findUserId(email: string): Promise<string | null> {
  for (let page = 1; ; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 })
    if (error) throw error
    const hit = data.users.find((u) => u.email === email)
    if (hit) return hit.id
    if (data.users.length < 200) return null
  }
}

async function ensureUser(email: string, fullName: string): Promise<string> {
  const attrs = { password, email_confirm: true, user_metadata: { full_name: fullName } }
  const existing = await findUserId(email)
  if (existing) {
    const { error } = await admin.auth.admin.updateUserById(existing, attrs)
    if (error) throw error
    return existing
  }
  const { data, error } = await admin.auth.admin.createUser({ email, ...attrs })
  if (error) throw error
  return data.user.id
}

const ids = new Map<string, string>()
for (const u of users) ids.set(u.email, await ensureUser(u.email, u.fullName))
const ownerId = ids.get(users[0].email)!

const { data: ws, error: wsError } = await admin
  .from('workspaces')
  .upsert(
    { slug, name: 'BounceWith Demo', type: 'other', require_approval: true, created_by: ownerId },
    { onConflict: 'slug' },
  )
  .select('id')
  .single()
if (wsError) throw wsError

const { error: mError } = await admin.from('memberships').upsert(
  users.map((u) => ({
    workspace_id: ws.id,
    user_id: ids.get(u.email)!,
    role: u.role,
    status: 'active' as const,
  })),
  { onConflict: 'workspace_id,user_id' },
)
if (mError) throw mError

console.log(`Workspace "${slug}" ready at ${url}`)
for (const u of users) console.log(`  ${u.role.padEnd(6)} ${u.email}`)
if (!process.env.DEMO_PASSWORD) console.log(`  password (shown once): ${password}`)
