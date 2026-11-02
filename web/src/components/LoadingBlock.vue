<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
</script>

<template>
  <div class="text-center py-5" role="status">
    <span class="spinner-border" aria-hidden="true"></span>
    <span class="visually-hidden">{{ t('common.loading') }}</span>
  </div>
</template>
