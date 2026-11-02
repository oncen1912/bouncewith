<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import * as api from '../api'
import type { Member } from '../types'
import MemberName from './MemberName.vue'

const props = defineProps<{ workspaceId: string; members: Member[] }>()
const emit = defineEmits<{ changed: [] }>()
const { t } = useI18n()
const busy = ref<string | null>(null)

async function act(action: 'approve' | 'decline', member: Member) {
  busy.value = member.user_id
  try {
    if (action === 'approve') await api.approveMember(props.workspaceId, member.user_id)
    else await api.removeMember(props.workspaceId, member.user_id)
    toast.success(
      t(action === 'approve' ? 'members.approved' : 'members.declined', { name: member.full_name }),
    )
    emit('changed')
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = null
  }
}
</script>

<template>
  <section class="card card-body border-warning" aria-labelledby="pending-title">
    <h2 id="pending-title" class="h6 mb-3">
      <i class="bi bi-hourglass-split text-warning me-1" aria-hidden="true"></i>
      {{ t('members.pendingTitle', { n: members.length }) }}
    </h2>
    <ul class="list-unstyled d-grid gap-3 m-0">
      <li v-for="m in members" :key="m.user_id" class="d-flex flex-wrap align-items-center gap-2">
        <MemberName :member="m" class="flex-grow-1" />
        <div class="d-flex gap-2">
          <button
            type="button"
            class="btn btn-outline-secondary"
            :disabled="busy === m.user_id"
            @click="act('decline', m)"
          >
            {{ t('members.decline') }}
          </button>
          <button
            type="button"
            class="btn btn-primary"
            :disabled="busy === m.user_id"
            @click="act('approve', m)"
          >
            {{ t('members.approve') }}
          </button>
        </div>
      </li>
    </ul>
  </section>
</template>
