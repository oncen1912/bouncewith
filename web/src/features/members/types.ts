import type { Database, Tables } from '@bouncewith/shared/database.types'

type Row = Database['public']['Functions']['workspace_members']['Returns'][number]
// avatar_url is nullable in the table; generated function types say otherwise
export type Member = Omit<Row, 'avatar_url'> & { avatar_url: string | null }
export type Group = Pick<Tables<'groups'>, 'id' | 'name'>
