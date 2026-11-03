import { supabase } from '@/app/supabase'
import type { Role } from '@/features/workspace/types'
import type { Group, Member } from './types'

export async function listMembers(workspaceId: string): Promise<Member[]> {
  const { data, error } = await supabase.rpc('workspace_members', { p_ws: workspaceId })
  if (error) throw error
  return data as Member[]
}

async function call(
  fn: 'approve_member' | 'block_member' | 'remove_member',
  workspaceId: string,
  userId: string,
) {
  const { error } = await supabase.rpc(fn, { p_ws: workspaceId, p_user: userId })
  if (error) throw error
}

export const approveMember = (ws: string, user: string) => call('approve_member', ws, user)
export const blockMember = (ws: string, user: string) => call('block_member', ws, user)
export const removeMember = (ws: string, user: string) => call('remove_member', ws, user)

export async function setRole(workspaceId: string, userId: string, role: Role) {
  const { error } = await supabase.rpc('set_member_role', { p_ws: workspaceId, p_user: userId, p_role: role })
  if (error) throw error
}

export async function listGroups(workspaceId: string): Promise<Group[]> {
  const { data, error } = await supabase
    .from('groups')
    .select('id, name')
    .eq('workspace_id', workspaceId)
    .order('name')
  if (error) throw error
  return data
}

export async function createGroup(workspaceId: string, name: string): Promise<Group> {
  const { data, error } = await supabase
    .from('groups')
    .insert({ workspace_id: workspaceId, name })
    .select('id, name')
    .single()
  if (error) throw error
  return data
}

export async function renameGroup(groupId: string, name: string) {
  const { error } = await supabase.from('groups').update({ name }).eq('id', groupId)
  if (error) throw error
}

export async function deleteGroup(groupId: string) {
  const { error } = await supabase.from('groups').delete().eq('id', groupId)
  if (error) throw error
}

/** Adds and removes group_members rows so that exactly `next` pairs exist, compared with `before`. */
export async function syncGroupMembers(
  workspaceId: string,
  before: { group_id: string; user_id: string }[],
  next: { group_id: string; user_id: string }[],
) {
  const key = (p: { group_id: string; user_id: string }) => `${p.group_id}:${p.user_id}`
  const beforeKeys = new Set(before.map(key))
  const nextKeys = new Set(next.map(key))
  const added = next.filter((p) => !beforeKeys.has(key(p)))
  const removed = before.filter((p) => !nextKeys.has(key(p)))

  if (added.length) {
    const { error } = await supabase
      .from('group_members')
      .insert(added.map((p) => ({ ...p, workspace_id: workspaceId })))
    if (error) throw error
  }
  for (const p of removed) {
    const { error } = await supabase
      .from('group_members')
      .delete()
      .eq('group_id', p.group_id)
      .eq('user_id', p.user_id)
    if (error) throw error
  }
}
