<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import * as api from '../api'
import type { Group, Member } from '../types'

const open = defineModel<boolean>('open', { required: true })
const props = defineProps<{ workspaceId: string; group: Group; members: Member[] }>()
const emit = defineEmits<{ changed: [] }>()
const { t } = useI18n()

const name = ref(props.group.name)
const initial = props.members.filter((m) => m.group_ids.includes(props.group.id)).map((m) => m.user_id)
const selected = ref<string[]>([...initial])
const query = ref('')
const confirmDelete = ref(false)
const busy = ref(false)

const visible = computed(() => {
  const q = query.value.trim().toLowerCase()
  return props.members.filter(
    (m) => !q || m.full_name.toLowerCase().includes(q) || m.email.toLowerCase().includes(q),
  )
})

async function run(action: () => Promise<unknown>, okKey: string) {
  busy.value = true
  try {
    await action()
    toast.success(t(okKey))
    emit('changed')
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}

const save = () =>
  run(async () => {
    if (name.value.trim() !== props.group.name) await api.renameGroup(props.group.id, name.value.trim())
    const pairs = (ids: string[]) => ids.map((user_id) => ({ group_id: props.group.id, user_id }))
    await api.syncGroupMembers(props.workspaceId, pairs(initial), pairs(selected.value))
  }, 'me.saved')

const remove = () => run(() => api.deleteGroup(props.group.id), 'members.groupDeleted')
</script>

<template>
  <BaseDialog v-model:open="open" :title="group.name">
    <form id="group-form" class="d-grid gap-3" @submit.prevent="save">
      <div>
        <label for="group-name" class="form-label">{{ t('members.groupName') }}</label>
        <input id="group-name" v-model="name" class="form-control" maxlength="60" required />
      </div>
      <fieldset>
        <legend class="form-label fs-6">{{ t('members.groupMembers', { n: selected.length }) }}</legend>
        <label for="group-search" class="visually-hidden">{{ t('members.search') }}</label>
        <input
          id="group-search"
          v-model="query"
          type="search"
          class="form-control mb-2"
          :placeholder="t('members.search')"
        />
        <div class="bw-checklist">
          <div v-for="m in visible" :key="m.user_id" class="form-check">
            <input
              :id="`gm-${m.user_id}`"
              v-model="selected"
              class="form-check-input"
              type="checkbox"
              :value="m.user_id"
            />
            <label class="form-check-label" :for="`gm-${m.user_id}`">{{ m.full_name || m.email }}</label>
          </div>
        </div>
      </fieldset>
    </form>

    <div class="border-top border-secondary-subtle mt-4 pt-3">
      <div v-if="confirmDelete" class="d-flex flex-wrap align-items-center gap-2" role="alert">
        <span class="flex-grow-1">{{ t('members.deleteGroupConfirm') }}</span>
        <button type="button" class="btn btn-outline-secondary" @click="confirmDelete = false">
          {{ t('common.cancel') }}
        </button>
        <button type="button" class="btn btn-danger" :disabled="busy" @click="remove">
          {{ t('common.delete') }}
        </button>
      </div>
      <button v-else type="button" class="btn btn-outline-danger" @click="confirmDelete = true">
        {{ t('members.deleteGroup') }}
      </button>
    </div>

    <template #footer>
      <button type="button" class="btn btn-outline-secondary" @click="open = false">
        {{ t('common.cancel') }}
      </button>
      <button type="submit" form="group-form" class="btn btn-primary" :disabled="busy">
        {{ t('common.save') }}
      </button>
    </template>
  </BaseDialog>
</template>

<style scoped>
.bw-checklist {
  max-height: 40dvh;
  overflow-y: auto;
}

.bw-checklist .form-check {
  min-height: 44px;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
</style>
