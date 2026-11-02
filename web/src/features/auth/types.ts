import type { Tables, TablesUpdate } from '@bouncewith/shared/database.types'

export type Profile = Tables<'profiles'>
export type ProfilePatch = Pick<
  TablesUpdate<'profiles'>,
  'full_name' | 'locale' | 'notify_email' | 'notify_push'
>
