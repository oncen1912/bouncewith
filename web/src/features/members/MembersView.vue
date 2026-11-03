<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import LoadingBlock from '@/components/LoadingBlock.vue'
import { useWorkspaceStore } from '@/features/workspace/store'
import * as api from './api'
import GroupsPanel from './components/GroupsPanel.vue'
import MemberList from './components/MemberList.vue'
import PendingRequests from './components/PendingRequests.vue'
import type { Group, Member } from './types'
import PageHeader from '@/components/PageHeader.vue'

const { t } = useI18n()
const workspaces = useWorkspaceStore()
const workspaceId = computed(() => workspaces.current?.workspace_id ?? '')

const members = ref<Member[]>([])
const groups = ref<Group[]>([])
const loading = ref(true)
const tab = ref<'members' | 'groups'>('members')

const pending = computed(() => members.value.filter((m) => m.status === 'pending'))

async function reload() {
  try {
    ;[members.value, groups.value] = await Promise.all([
      api.listMembers(workspaceId.value),
      api.listGroups(workspaceId.value),
    ])
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
}

onMounted(reload)
</script>

<template>
  <PageHeader :title="t('nav.members')" :eyebrow="workspaces.current?.name" />
  <LoadingBlock v-if="loading" />

  <template v-else>
    <PendingRequests
      v-if="pending.length"
      :workspace-id="workspaceId"
      :members="pending"
      class="mb-4"
      @changed="reload"
    />

    <div class="btn-group w-100 mb-3" role="group" :aria-label="t('members.view')">
      <input id="tab-members" v-model="tab" type="radio" class="btn-check" value="members" />
      <label class="btn btn-outline-secondary" for="tab-members">{{ t('nav.members') }}</label>
      <input id="tab-groups" v-model="tab" type="radio" class="btn-check" value="groups" />
      <label class="btn btn-outline-secondary" for="tab-groups">{{ t('members.groups') }}</label>
    </div>

    <MemberList
      v-if="tab === 'members'"
      :workspace-id="workspaceId"
      :members="members"
      :groups="groups"
      @changed="reload"
    />
    <GroupsPanel v-else :workspace-id="workspaceId" :members="members" :groups="groups" @changed="reload" />
  </template>
</template>
