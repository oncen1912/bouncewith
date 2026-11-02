/** Only allow same-origin paths as post-login targets (no open redirects). */
export function safeRedirect(value: unknown, fallback = '/w'): string {
  if (typeof value !== 'string') return fallback
  if (!value.startsWith('/') || value.startsWith('//') || value.startsWith('/\\')) return fallback
  if (value.startsWith('/login') || value.startsWith('/auth/')) return fallback
  return value
}
