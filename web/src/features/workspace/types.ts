import type { Enums, Tables } from '@bouncewith/shared/database.types'

export type Workspace = Pick<
  Tables<'workspaces'>,
  'id' | 'slug' | 'name' | 'type' | 'timezone' | 'accent_color' | 'logo_url'
>
export type MyWorkspace = Workspace & { role: Enums<'member_role'> }
