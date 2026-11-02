import { createI18n } from 'vue-i18n'
import en from '@/locales/en.json'
import sl from '@/locales/sl.json'
import de from '@/locales/de.json'
import { detectLocale, storeLocale, storedLocale, type AppLocale } from './locale'

export type MessageSchema = typeof en

declare module 'vue-i18n' {
  // typed keys for t('…'), with en.json as the source of truth
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  export interface DefineLocaleMessage extends MessageSchema {}
}

const initial = detectLocale(storedLocale(), navigator.languages ?? [navigator.language])

export const i18n = createI18n<[MessageSchema], AppLocale, false>({
  legacy: false,
  locale: initial,
  fallbackLocale: 'en',
  messages: { en, sl, de },
})

export function setLocale(locale: AppLocale) {
  i18n.global.locale.value = locale
  document.documentElement.lang = locale
  storeLocale(locale)
}

document.documentElement.lang = initial
