<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { safeRedirect } from '@/app/redirect'
import EmptyState from '@/components/EmptyState.vue'
import { useAuthStore } from './store'

// Landing page for magic links, e-mail confirmation and Google. supabase-js exchanges the ?code= on init.
const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const failed = ref(false)

onMounted(async () => {
  await auth.init()
  if (auth.isAuthenticated) await router.replace(safeRedirect(route.query.next))
  else failed.value = true
})
</script>

<template>
  <main class="container py-5" style="max-width: 480px">
    <EmptyState
      v-if="failed"
      icon="bi-link-45deg"
      :title="t('auth.callbackFailed')"
      :text="t('auth.callbackFailedText')"
    >
      <RouterLink :to="{ name: 'login' }" class="btn btn-primary mt-3">{{
        t('auth.backToLogin')
      }}</RouterLink>
    </EmptyState>
    <div v-else class="text-center" role="status">
      <span class="spinner-border" aria-hidden="true"></span>
      <p class="mt-3">{{ t('auth.signingIn') }}</p>
    </div>
  </main>
</template>
