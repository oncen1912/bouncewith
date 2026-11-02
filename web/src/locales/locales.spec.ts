import { describe, expect, it } from 'vitest'
import en from './en.json'
import sl from './sl.json'
import de from './de.json'

type Tree = { [key: string]: string | Tree }

function flatten(tree: Tree, prefix = ''): Record<string, string> {
  return Object.entries(tree).reduce<Record<string, string>>((acc, [k, v]) => {
    const key = prefix ? `${prefix}.${k}` : k
    return typeof v === 'string' ? { ...acc, [key]: v } : { ...acc, ...flatten(v, key) }
  }, {})
}

const flat = { en: flatten(en), sl: flatten(sl), de: flatten(de) }
const placeholders = (s: string) => [...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort()

describe('locales', () => {
  it.each(['sl', 'de'] as const)('%s has exactly the keys of en', (lang) => {
    expect(Object.keys(flat[lang]).sort()).toEqual(Object.keys(flat.en).sort())
  })

  it.each(['sl', 'de'] as const)('%s uses the same {placeholders} as en', (lang) => {
    for (const [key, text] of Object.entries(flat.en)) {
      expect(placeholders(flat[lang][key] ?? ''), key).toEqual(placeholders(text))
    }
  })

  it('has no empty strings or vue-i18n special characters (| @ $)', () => {
    for (const lang of Object.values(flat)) {
      for (const [key, text] of Object.entries(lang)) {
        expect(text.trim(), key).not.toBe('')
        expect(text, key).not.toMatch(/[|@$]/)
      }
    }
  })
})
