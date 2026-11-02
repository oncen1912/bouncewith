<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import EmptyState from '@/components/EmptyState.vue'
import * as api from '../api'
import type { Group, Member } from '../types'
import GroupDialog from './GroupDialog.vue'

const props = defineProps<{ workspaceId: string; members: Member[]; groups: Group[] }>()
const emit = defineEmits<{ changed: [] }>()
const { t } = useI18n()

const newName = ref('')
const busy = ref(false)
const editing = ref<Group | null>(null)
const dialogOpen = computed({
  get: () => !!editing.value,
  set: (open) => {
    if (!open) editing.value = null
  },
})

const counts = computed(() => {
  const map = new Map<string, number>()
  for (const m of props.members) for (const g of m.group_ids) map.set(g, (map.get(g) ?? 0) + 1)
  return map
})

async function create() {
  busy.value = true
  try {
    editing.value = await api.createGroup(props.workspaceId, newName.value.trim())
    newName.value = ''
    emit('changed')
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}

function onChanged() {
  editing.value = null
  emit('changed')
}
</script>

<template>
  <form class="d-flex gap-2 mb-3" @submit.prevent="create">
    <label for="new-group" class="visually-hidden">{{ t('members.newGroup') }}</label>
    <input
      id="new-group"
      v-model="newName"
      class="form-control"
      :placeholder="t('members.newGroup')"
      maxlength="60"
      required
    />
    <button type="submit" class="btn btn-primary flex-none" :disabled="busy">
      <i class="bi bi-plus-lg me-1" aria-hidden="true"></i>{{ t('members.addGroup') }}
    </button>
  </form>

  <EmptyState
    v-if="groups.length === 0"
    icon="bi-collection"
    :title="t('members.noGroups')"
    :text="t('members.noGroupsText')"
  />

  <ul v-else class="list-unstyled d-grid gap-2 m-0">
    <li v-for="g in groups" :key="g.id">
      <button type="button" class="card card-body bw-group w-100 text-start" @click="editing = g">
        <span class="fw-semibold flex-grow-1 text-truncate">{{ g.name }}</span>
        <span class="small text-muted">{{ t('members.groupCount', { n: counts.get(g.id) ?? 0 }) }}</span>
        <i class="bi bi-chevron-right text-muted" aria-hidden="true"></i>
      </button>
    </li>
  </ul>

  <GroupDialog
    v-if="editing"
    v-model:open="dialogOpen"
    :workspace-id="workspaceId"
    :group="editing"
    :members="members.filter((m) => m.status === 'active')"
    @changed="onChanged"
  />
</template>

<style scoped>
.bw-group {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 0.75rem;
  color: var(--bw-text);
}

.bw-group:hover {
  border-color: var(--bw-accent);
}

.bw-group:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: 2px;
}
</style>
