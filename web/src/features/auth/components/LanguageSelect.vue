<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { setLocale } from '@/app/i18n'
import { SUPPORTED_LOCALES, isSupportedLocale, type AppLocale } from '@/app/locale'

const emit = defineEmits<{ change: [locale: AppLocale] }>()
const { t, locale } = useI18n()

const model = computed({
  get: () => locale.value,
  set: (value: string) => {
    if (!isSupportedLocale(value)) return
    setLocale(value)
    emit('change', value)
  },
})
</script>

<template>
  <label for="lang-select" class="visually-hidden">{{ t('me.language') }}</label>
  <select id="lang-select" v-model="model" class="form-select">
    <option v-for="l in SUPPORTED_LOCALES" :key="l" :value="l">{{ t(`languages.${l}`) }}</option>
  </select>
</template>
