import { supabase } from '@/app/supabase'
import type {
  MyMembership,
  WorkspacePatch,
  WorkspacePreview,
  WorkspaceSettings,
  WorkspaceType,
} from './types'

export async function listMyMemberships(): Promise<MyMembership[]> {
  const { data, error } = await supabase.rpc('my_memberships')
  if (error) throw error
  return data as MyMembership[]
}

export async function createWorkspace(name: string, slug: string, type: WorkspaceType, timezone: string) {
  const { data, error } = await supabase.rpc('create_workspace', {
    p_name: name,
    p_slug: slug,
    p_type: type,
    p_timezone: timezone,
  })
  if (error) throw error
  return data
}

export async function previewByCode(code: string): Promise<WorkspacePreview | null> {
  const { data, error } = await supabase.rpc('workspace_preview', { p_code: code })
  if (error) throw error
  return (data[0] as WorkspacePreview | undefined) ?? null
}

export async function joinByCode(code: string) {
  const { data, error } = await supabase.rpc('join_workspace', { p_code: code })
  if (error) throw error
  return data
}

export async function leaveWorkspace(workspaceId: string) {
  const { error } = await supabase.rpc('leave_workspace', { p_ws: workspaceId })
  if (error) throw error
}

export async function getSettings(workspaceId: string): Promise<WorkspaceSettings> {
  const { data, error } = await supabase.from('workspaces').select('*').eq('id', workspaceId).single()
  if (error) throw error
  return data
}

export async function updateSettings(workspaceId: string, patch: WorkspacePatch) {
  const { error } = await supabase.from('workspaces').update(patch).eq('id', workspaceId)
  if (error) throw error
}

export async function regenerateJoinCode(workspaceId: string) {
  const { data, error } = await supabase.rpc('regenerate_join_code', { p_ws: workspaceId })
  if (error) throw error
  return data
}

const LOGO_TYPES: Record<string, string> = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/webp': 'webp' }
export const LOGO_MAX_BYTES = 1024 * 1024

/** Uploads a logo to {workspace_id}/logo-{time}.{ext} and returns its public URL. */
export async function uploadLogo(workspaceId: string, file: File): Promise<string> {
  const ext = LOGO_TYPES[file.type]
  if (!ext) throw new Error('logo_type')
  if (file.size > LOGO_MAX_BYTES) throw new Error('logo_size')
  const path = `${workspaceId}/logo-${Date.now()}.${ext}`
  const bucket = supabase.storage.from('workspace-logos')
  const { error } = await bucket.upload(path, file, { contentType: file.type, cacheControl: '31536000' })
  if (error) throw error
  return bucket.getPublicUrl(path).data.publicUrl
}
