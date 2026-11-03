<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import EmptyState from '@/components/EmptyState.vue'
import type { Group, Member } from '../types'
import MemberDialog from './MemberDialog.vue'
import MemberName from './MemberName.vue'

const props = defineProps<{ workspaceId: string; members: Member[]; groups: Group[] }>()
const emit = defineEmits<{ changed: [] }>()
const { t } = useI18n()

const query = ref('')
const showBlocked = ref(false)
const selected = ref<Member | null>(null)
const dialogOpen = computed({
  get: () => !!selected.value,
  set: (open) => {
    if (!open) selected.value = null
  },
})

const groupName = computed(() => new Map(props.groups.map((g) => [g.id, g.name])))
const blockedCount = computed(() => props.members.filter((m) => m.status === 'blocked').length)
const visible = computed(() => {
  const q = query.value.trim().toLowerCase()
  return props.members.filter(
    (m) =>
      m.status === (showBlocked.value ? 'blocked' : 'active') &&
      (!q || m.full_name.toLowerCase().includes(q) || m.email.toLowerCase().includes(q)),
  )
})

function onChanged() {
  selected.value = null
  emit('changed')
}
</script>

<template>
  <div class="d-flex flex-wrap gap-2 mb-3">
    <label for="member-search" class="visually-hidden">{{ t('members.search') }}</label>
    <input
      id="member-search"
      v-model="query"
      type="search"
      class="form-control flex-grow-1"
      style="max-width: 360px"
      :placeholder="t('members.search')"
    />
    <div v-if="blockedCount" class="form-check form-switch align-self-center ms-auto">
      <input id="show-blocked" v-model="showBlocked" class="form-check-input" type="checkbox" role="switch" />
      <label class="form-check-label" for="show-blocked">{{
        t('members.showBlocked', { n: blockedCount })
      }}</label>
    </div>
  </div>

  <EmptyState v-if="visible.length === 0" icon="bi-people" :title="t('members.noneFound')" />

  <ul v-else class="list-unstyled d-grid gap-2 m-0">
    <li v-for="m in visible" :key="m.user_id">
      <button type="button" class="card card-body bw-member w-100 text-start" @click="selected = m">
        <MemberName :member="m" class="flex-grow-1" />
        <span class="d-flex flex-wrap gap-1 justify-content-end">
          <span v-for="g in m.group_ids" :key="g" class="badge text-bg-secondary">{{
            groupName.get(g)
          }}</span>
          <span v-if="m.role !== 'member'" class="badge bw-role">{{ t(`roles.${m.role}`) }}</span>
        </span>
        <i class="bi bi-chevron-right text-muted" aria-hidden="true"></i>
      </button>
    </li>
  </ul>

  <MemberDialog
    v-if="selected"
    v-model:open="dialogOpen"
    :workspace-id="workspaceId"
    :member="selected"
    :groups="groups"
    @changed="onChanged"
  />
</template>

<style scoped>
.bw-member {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 0.75rem;
  color: var(--bw-text);
}

.bw-member:hover {
  border-color: var(--bw-accent);
}

.bw-member:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: 2px;
}

.bw-role {
  background: color-mix(in srgb, var(--bw-accent) 25%, transparent);
  color: var(--bw-text);
}
</style>
