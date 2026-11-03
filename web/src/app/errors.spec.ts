import { describe, expect, it } from 'vitest'
import { errorKey, rpcCode } from './errors'

describe('errorKey', () => {
  it('maps our RPC codes', () => {
    expect(errorKey({ code: 'P0001', message: 'last_owner' })).toBe('errors.codes.last_owner')
    expect(rpcCode({ code: 'P0001', message: 'slug_taken' })).toBe('slug_taken')
  })

  it('does not trust arbitrary P0001 messages', () => {
    expect(errorKey({ code: 'P0001', message: 'something else' })).toBe('errors.generic')
  })

  it('maps unique violations and falls back to generic', () => {
    expect(errorKey({ code: '23505', message: 'duplicate key' })).toBe('errors.duplicate')
    expect(errorKey(new Error('x'))).toBe('errors.generic')
  })
})
