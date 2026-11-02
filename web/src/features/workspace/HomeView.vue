<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import EmptyState from '@/components/EmptyState.vue'
import { useAuthStore } from '@/features/auth/store'
import { useWorkspaceStore } from './store'

const { t } = useI18n()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()

const firstName = computed(() => auth.profile?.full_name.split(' ')[0] ?? '')
</script>

<template>
  <div v-if="!workspaces.loaded" class="text-center py-5" role="status">
    <span class="spinner-border" aria-hidden="true"></span>
    <span class="visually-hidden">{{ t('common.loading') }}</span>
  </div>

  <EmptyState
    v-else-if="!workspaces.current"
    icon="bi-shield-lock"
    :title="t('home.noAccessTitle')"
    :text="t('home.noAccessText')"
  >
    <RouterLink :to="{ name: 'workspaces' }" class="btn btn-primary mt-3">{{
      t('nav.workspaces')
    }}</RouterLink>
  </EmptyState>

  <template v-else>
    <p class="text-muted mb-1">{{ workspaces.current.name }}</p>
    <h1 class="h3 mb-4">
      {{ firstName ? t('home.greetingName', { name: firstName }) : t('home.greeting') }}
    </h1>

    <section class="mb-4" aria-labelledby="next-events">
      <h2 id="next-events" class="h5">{{ t('home.nextEvents') }}</h2>
      <EmptyState icon="bi-calendar-event" :title="t('home.noEventsTitle')" :text="t('home.noEventsText')" />
    </section>

    <section aria-labelledby="messages">
      <h2 id="messages" class="h5">{{ t('home.messages') }}</h2>
      <EmptyState icon="bi-chat-dots" :title="t('home.noMessagesTitle')" />
    </section>
  </template>
</template>
