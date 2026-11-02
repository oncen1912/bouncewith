import type { Database, Enums, Tables } from '@bouncewith/shared/database.types'

export type Role = Enums<'member_role'>
export type MembershipStatus = Enums<'membership_status'>
export type WorkspaceType = Enums<'workspace_type'>

type Fn<N extends keyof Database['public']['Functions']> = Database['public']['Functions'][N]['Returns']
// Generated types mark every column of `returns table (...)` as non-null; restore the nullable ones.
type Nullable<T, K extends keyof T> = Omit<T, K> & { [P in K]: T[P] | null }

/** A row of my_memberships(): my workspaces including pending requests. */
export type MyMembership = Nullable<Fn<'my_memberships'>[number], 'accent_color' | 'logo_url'>
export type WorkspacePreview = Nullable<
  Fn<'workspace_preview'>[number],
  'accent_color' | 'logo_url' | 'my_status'
>
export type WorkspaceSettings = Tables<'workspaces'>
export type WorkspacePatch = Partial<
  Pick<
    WorkspaceSettings,
    'name' | 'type' | 'timezone' | 'logo_url' | 'accent_color' | 'require_approval' | 'allow_self_absence'
  >
>

export const WORKSPACE_TYPES: WorkspaceType[] = ['dance', 'fitness', 'yoga', 'other']
const RANK: Record<Role, number> = { member: 0, trainer: 1, owner: 2 }

export function hasRole(role: Role | null | undefined, min: Role): boolean {
  return !!role && RANK[role] >= RANK[min]
}
