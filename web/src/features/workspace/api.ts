import { supabase } from '@/app/supabase'
import type { MyWorkspace } from './types'

/** Active workspaces of the signed-in user. RLS hides workspaces where the membership isn't active. */
export async function listMyWorkspaces(userId: string): Promise<MyWorkspace[]> {
  const { data, error } = await supabase
    .from('memberships')
    .select('role, workspace:workspaces (id, slug, name, type, timezone, accent_color, logo_url)')
    .eq('user_id', userId)
    .eq('status', 'active')
  if (error) throw error
  return data
    .flatMap(({ role, workspace }) => (workspace ? [{ ...workspace, role }] : []))
    .sort((a, b) => a.name.localeCompare(b.name))
}
