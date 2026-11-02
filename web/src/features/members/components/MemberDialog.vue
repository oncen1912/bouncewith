<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import { useAuthStore } from '@/features/auth/store'
import { useWorkspaceStore } from '@/features/workspace/store'
import type { Role } from '@/features/workspace/types'
import * as api from '../api'
import type { Group, Member } from '../types'

const open = defineModel<boolean>('open', { required: true })
const props = defineProps<{ workspaceId: string; member: Member; groups: Group[] }>()
const emit = defineEmits<{ changed: [] }>()
const { t } = useI18n()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()

const isSelf = computed(() => props.member.user_id === auth.user?.id)
const canManage = computed(() => !isSelf.value && (props.member.role !== 'owner' || workspaces.isOwner))
const role = ref<Role>(props.member.role)
const groupIds = ref<string[]>([...props.member.group_ids])
const confirmRemove = ref(false)
const busy = ref(false)

async function run(action: () => Promise<unknown>, okKey: string) {
  busy.value = true
  try {
    await action()
    toast.success(t(okKey, { name: props.member.full_name }))
    emit('changed')
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}

const save = () =>
  run(async () => {
    if (workspaces.isOwner && role.value !== props.member.role)
      await api.setRole(props.workspaceId, props.member.user_id, role.value)
    const pairs = (ids: string[]) => ids.map((group_id) => ({ group_id, user_id: props.member.user_id }))
    await api.syncGroupMembers(props.workspaceId, pairs(props.member.group_ids), pairs(groupIds.value))
  }, 'me.saved')

const block = () => run(() => api.blockMember(props.workspaceId, props.member.user_id), 'members.blocked')
const unblock = () =>
  run(() => api.approveMember(props.workspaceId, props.member.user_id), 'members.unblocked')
const remove = () => run(() => api.removeMember(props.workspaceId, props.member.user_id), 'members.removed')
</script>

<template>
  <BaseDialog v-model:open="open" :title="member.full_name || member.email">
    <p class="small text-muted">{{ member.email }}</p>

    <template v-if="member.status === 'blocked'">
      <p>{{ t('members.blockedInfo') }}</p>
      <button v-if="canManage" type="button" class="btn btn-primary" :disabled="busy" @click="unblock">
        {{ t('members.unblock') }}
      </button>
    </template>

    <form v-else id="member-form" class="d-grid gap-3" @submit.prevent="save">
      <div v-if="workspaces.isOwner">
        <label for="member-role" class="form-label">{{ t('members.role') }}</label>
        <select id="member-role" v-model="role" class="form-select">
          <option v-for="r in ['member', 'trainer', 'owner'] as const" :key="r" :value="r">
            {{ t(`roles.${r}`) }}
          </option>
        </select>
        <div v-if="role === 'owner' && member.role !== 'owner'" class="form-text text-warning">
          {{ t('members.ownerWarning') }}
        </div>
      </div>

      <fieldset v-if="groups.length">
        <legend class="form-label fs-6">{{ t('members.groups') }}</legend>
        <div v-for="g in groups" :key="g.id" class="form-check">
          <input
            :id="`mg-${g.id}`"
            v-model="groupIds"
            class="form-check-input"
            type="checkbox"
            :value="g.id"
          />
          <label class="form-check-label" :for="`mg-${g.id}`">{{ g.name }}</label>
        </div>
      </fieldset>
    </form>

    <div v-if="canManage && member.status === 'active'" class="border-top border-secondary-subtle mt-4 pt-3">
      <div v-if="confirmRemove" class="d-grid gap-2" role="alert">
        <p class="mb-1">{{ t('members.removeConfirm', { name: member.full_name }) }}</p>
        <div class="d-flex gap-2">
          <button type="button" class="btn btn-outline-secondary" @click="confirmRemove = false">
            {{ t('common.cancel') }}
          </button>
          <button type="button" class="btn btn-danger" :disabled="busy" @click="remove">
            {{ t('members.remove') }}
          </button>
        </div>
      </div>
      <div v-else class="d-flex flex-wrap gap-2">
        <button type="button" class="btn btn-outline-danger" :disabled="busy" @click="block">
          {{ t('members.block') }}
        </button>
        <button type="button" class="btn btn-outline-danger" @click="confirmRemove = true">
          {{ t('members.remove') }}
        </button>
      </div>
      <p class="form-text mb-0 mt-2">{{ t('members.blockHelp') }}</p>
    </div>

    <template v-if="member.status === 'active'" #footer>
      <button type="button" class="btn btn-outline-secondary" @click="open = false">
        {{ t('common.cancel') }}
      </button>
      <button type="submit" form="member-form" class="btn btn-primary" :disabled="busy">
        {{ t('common.save') }}
      </button>
    </template>
  </BaseDialog>
</template>
