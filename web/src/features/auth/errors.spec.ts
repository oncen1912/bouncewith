import { describe, expect, it } from 'vitest'
import { authErrorKey } from './errors'

describe('authErrorKey', () => {
  it('maps known Supabase auth codes', () => {
    expect(authErrorKey({ code: 'invalid_credentials', message: 'Invalid login credentials' })).toBe(
      'auth.errors.invalid_credentials',
    )
  })

  it('falls back to a generic message', () => {
    expect(authErrorKey({ code: 'something_new' })).toBe('errors.generic')
    expect(authErrorKey(new Error('boom'))).toBe('errors.generic')
    expect(authErrorKey(null)).toBe('errors.generic')
  })
})
