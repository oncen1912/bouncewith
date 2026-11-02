import { createClient } from '@supabase/supabase-js'
import type { Database } from '@bouncewith/shared/database.types'

// Browser client: publishable key only (CLAUDE.md rule 4). RLS is the security boundary.
export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
  { auth: { flowType: 'pkce', persistSession: true, detectSessionInUrl: true } },
)
