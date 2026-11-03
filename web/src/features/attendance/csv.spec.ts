import { describe, expect, it } from 'vitest'
import { toCsv } from './csv'
import { attendanceRate } from './types'

describe('toCsv', () => {
  it('quotes commas, quotes and newlines and starts with a BOM', () => {
    expect(
      toCsv([
        ['Name', 'Reason'],
        ['Ana Kovač', 'Sick, "really"\nsorry'],
      ]),
    ).toBe('﻿Name,Reason\r\nAna Kovač,"Sick, ""really""\nsorry"\r\n')
  })

  it('neutralises formula injection', () => {
    expect(toCsv([['=HYPERLINK("x")', '+1', '-2', '@me', 5]])).toBe(
      '﻿"\'=HYPERLINK(""x"")",\'+1,\'-2,\'@me,5\r\n',
    )
  })

  it('writes empty cells for null', () => {
    expect(toCsv([[null, undefined, 0]])).toBe('﻿,,0\r\n')
  })
})

describe('attendanceRate', () => {
  it('is present / recorded, or null without records', () => {
    expect(attendanceRate({ present: 3, absent: 1 })).toBe(75)
    expect(attendanceRate({ present: 0, absent: 0 })).toBeNull()
  })
})
