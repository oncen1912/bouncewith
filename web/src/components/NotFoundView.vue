<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import EmptyState from './EmptyState.vue'

const { t } = useI18n()
</script>

<template>
  <main class="container py-5" style="max-width: 480px">
    <EmptyState icon="bi-signpost-split" :title="t('notFound.title')" :text="t('notFound.text')">
      <RouterLink :to="{ name: 'workspaces' }" class="btn btn-primary mt-3">{{
        t('notFound.back')
      }}</RouterLink>
    </EmptyState>
  </main>
</template>
