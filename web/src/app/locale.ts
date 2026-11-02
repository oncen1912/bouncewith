export const SUPPORTED_LOCALES = ['en', 'sl', 'de'] as const
export type AppLocale = (typeof SUPPORTED_LOCALES)[number]

const STORAGE_KEY = 'bw.locale'

export function isSupportedLocale(value: unknown): value is AppLocale {
  return typeof value === 'string' && (SUPPORTED_LOCALES as readonly string[]).includes(value)
}

/** Stored choice → first supported browser language → en. */
export function detectLocale(stored: string | null, browserLanguages: readonly string[]): AppLocale {
  if (isSupportedLocale(stored)) return stored
  for (const lang of browserLanguages) {
    const base = lang.toLowerCase().split('-')[0]
    if (isSupportedLocale(base)) return base
  }
  return 'en'
}

export function storedLocale(): string | null {
  try {
    return localStorage.getItem(STORAGE_KEY)
  } catch {
    return null
  }
}

export function storeLocale(locale: AppLocale) {
  try {
    localStorage.setItem(STORAGE_KEY, locale)
  } catch {
    // private mode: the choice simply isn't remembered
  }
}
