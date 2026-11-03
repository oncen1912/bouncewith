<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import { useAuthStore } from '@/features/auth/store'
import { useWorkspaceStore } from './store'
import PageHeader from '@/components/PageHeader.vue'
import NextEvents from '@/features/events/components/NextEvents.vue'

const { t } = useI18n()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()

const firstName = computed(() => auth.profile?.full_name.split(' ')[0] ?? '')
</script>

<template>
  <LoadingBlock v-if="!workspaces.loaded" />

  <EmptyState
    v-else-if="workspaces.currentPending"
    icon="bi-hourglass-split"
    :title="t('home.pendingTitle', { name: workspaces.currentPending.name })"
    :text="t('home.pendingText')"
  />

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
    <PageHeader
      :title="firstName ? t('home.greetingName', { name: firstName }) : t('home.greeting')"
      :eyebrow="workspaces.current.name"
    />

    <section class="mb-4" aria-labelledby="next-events">
      <h2 id="next-events" class="h3">{{ t('home.nextEvents') }}</h2>
      <NextEvents
        :workspace-id="workspaces.current.workspace_id"
        :slug="workspaces.current.slug"
        :is-trainer="workspaces.isTrainer"
      />
    </section>

    <section aria-labelledby="messages">
      <h2 id="messages" class="h3">{{ t('home.messages') }}</h2>
      <EmptyState icon="bi-chat-dots" :title="t('home.noMessagesTitle')" />
    </section>
  </template>
</template>
