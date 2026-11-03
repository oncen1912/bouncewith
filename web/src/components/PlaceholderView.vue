<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import EmptyState from './EmptyState.vue'
import PageHeader from '@/components/PageHeader.vue'

const route = useRoute()
const { t } = useI18n()
</script>

<template>
  <PageHeader :title="t(route.meta.titleKey ?? 'nav.home')" />
  <EmptyState icon="bi-cone-striped" :title="t('placeholder.title')" :text="t('placeholder.text')" />
</template>
