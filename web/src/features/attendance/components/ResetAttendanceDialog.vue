<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import * as api from '../api'

const open = defineModel<boolean>('open', { required: true })
const props = defineProps<{ eventId: string; title: string }>()
const emit = defineEmits<{ reset: [] }>()
const { t } = useI18n()
const typed = ref('')
const busy = ref(false)

async function submit() {
  busy.value = true
  try {
    const n = await api.resetAttendance(props.eventId, typed.value)
    toast.success(t('attendance.resetDone', { n }))
    typed.value = ''
    open.value = false
    emit('reset')
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <BaseDialog v-model:open="open" :title="t('attendance.resetTitle')">
    <form id="reset-form" @submit.prevent="submit">
      <p>{{ t('attendance.resetText') }}</p>
      <label for="reset-title" class="form-label">{{ t('attendance.resetType', { title }) }}</label>
      <input id="reset-title" v-model="typed" class="form-control" autocomplete="off" required />
    </form>
    <template #footer>
      <button type="button" class="btn btn-outline-secondary" @click="open = false">
        {{ t('common.cancel') }}
      </button>
      <button
        type="submit"
        form="reset-form"
        class="btn btn-danger"
        :disabled="busy || typed.trim() !== title.trim()"
      >
        {{ t('attendance.reset') }}
      </button>
    </template>
  </BaseDialog>
</template>
