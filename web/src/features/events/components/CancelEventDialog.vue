<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import * as api from '../api'
import type { EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'

const open = defineModel<boolean>('open', { required: true })
const props = defineProps<{ event: EventRow }>()
const emit = defineEmits<{ cancelled: [] }>()
const { t } = useI18n()
const f = useEventFormat()

const scope = ref<'this' | 'future'>('this')
const notify = ref(true)
const message = ref(
  t('events.cancelMessage', {
    title: props.event.title,
    date: f.date(props.event.starts_at),
    time: f.timeRange(props.event.starts_at, props.event.ends_at),
  }),
)
const busy = ref(false)

async function submit() {
  busy.value = true
  try {
    const n = await api.cancelEvent(props.event.id, scope.value, notify.value ? message.value.trim() : null)
    toast.success(t('events.cancelledToast', { n }))
    open.value = false
    emit('cancelled')
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <BaseDialog v-model:open="open" :title="t('events.cancelTitle')">
    <form id="cancel-form" class="d-grid gap-3" @submit.prevent="submit">
      <fieldset v-if="event.series_id">
        <legend class="form-label fs-6">{{ t('events.whichEvents') }}</legend>
        <div class="form-check">
          <input id="cs-this" v-model="scope" class="form-check-input" type="radio" value="this" />
          <label class="form-check-label" for="cs-this">{{ t('events.scopeThis') }}</label>
        </div>
        <div class="form-check">
          <input id="cs-future" v-model="scope" class="form-check-input" type="radio" value="future" />
          <label class="form-check-label" for="cs-future">{{ t('events.scopeFuture') }}</label>
        </div>
      </fieldset>
      <div class="form-check form-switch">
        <input id="cs-notify" v-model="notify" class="form-check-input" type="checkbox" role="switch" />
        <label class="form-check-label" for="cs-notify">{{ t('events.notifyInvited') }}</label>
      </div>
      <div v-if="notify">
        <label for="cs-message" class="form-label">{{ t('events.message') }}</label>
        <textarea
          id="cs-message"
          v-model="message"
          class="form-control"
          rows="3"
          maxlength="4000"
          required
        ></textarea>
        <div class="form-text">{{ t('events.notifyHelp') }}</div>
      </div>
    </form>
    <template #footer>
      <button type="button" class="btn btn-outline-secondary" @click="open = false">
        {{ t('common.close') }}
      </button>
      <button type="submit" form="cancel-form" class="btn btn-danger" :disabled="busy">
        {{ t('events.cancelEvent') }}
      </button>
    </template>
  </BaseDialog>
</template>
