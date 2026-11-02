<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import EmptyState from './EmptyState.vue'

const route = useRoute()
const { t } = useI18n()
</script>

<template>
  <h1 class="h3 mb-4">{{ t(route.meta.titleKey ?? 'nav.home') }}</h1>
  <EmptyState icon="bi-cone-striped" :title="t('placeholder.title')" :text="t('placeholder.text')" />
</template>
