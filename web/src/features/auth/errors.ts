const KNOWN = [
  'invalid_credentials',
  'email_not_confirmed',
  'user_already_exists',
  'weak_password',
  'over_email_send_rate_limit',
  'over_request_rate_limit',
  'provider_disabled',
  'email_address_invalid',
] as const

/** Maps a Supabase auth error to an i18n key so the UI never shows raw English server text. */
export function authErrorKey(error: unknown): string {
  const code =
    typeof error === 'object' && error && 'code' in error ? (error as { code?: unknown }).code : null
  return typeof code === 'string' && (KNOWN as readonly string[]).includes(code)
    ? `auth.errors.${code}`
    : 'errors.generic'
}
