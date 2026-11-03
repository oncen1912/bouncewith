// Stable error codes raised by the SQL functions (SPEC §5): `raise exception using message = '<code>'`.
const RPC_CODES = [
  'not_authenticated',
  'forbidden',
  'not_found',
  'not_active',
  'name_invalid',
  'slug_invalid',
  'slug_reserved',
  'slug_taken',
  'timezone_invalid',
  'workspace_limit',
  'invalid_code',
  'blocked',
  'cannot_target_self',
  'last_owner',
  'group_in_use',
  'confirm_mismatch',
  'group_invalid',
  'not_series',
  'invalid_scope',
  'message_required',
  'event_cancelled',
  'rsvp_closed',
  'self_absence_disabled',
  'event_full',
  'reason_too_long',
  'not_member',
  'not_invited',
  'invalid_minutes',
  'invalid_token',
  'token_expired',
] as const
export type RpcCode = (typeof RPC_CODES)[number]

function field(error: unknown, key: string): unknown {
  return typeof error === 'object' && error && key in error
    ? (error as Record<string, unknown>)[key]
    : undefined
}

/** The stable code of a failed RPC, if it is one of ours. */
export function rpcCode(error: unknown): RpcCode | null {
  const message = field(error, 'message')
  return field(error, 'code') === 'P0001' && (RPC_CODES as readonly unknown[]).includes(message)
    ? (message as RpcCode)
    : null
}

/** i18n key for any error coming back from Supabase. */
export function errorKey(error: unknown): string {
  const code = rpcCode(error)
  if (code) return `errors.codes.${code}`
  if (field(error, 'code') === '23505') return 'errors.duplicate'
  return 'errors.generic'
}
