<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import type { EventRow } from '@/features/events/types'
import { useAttendanceStore } from '../store'

// One tap to say "I'm in"; "Can't make it" asks for an optional reason.
const props = withDefaults(defineProps<{ event: EventRow; size?: 'sm' | 'lg' }>(), { size: 'sm' })
const { t } = useI18n()
const attendance = useAttendanceStore()

const mine = computed(() => attendance.mine[props.event.id]?.answer ?? null)
const going = computed(() => attendance.counts[props.event.id]?.going ?? 0)
const closed = computed(
  () =>
    props.event.status !== 'scheduled' ||
    Date.now() >= Date.parse(props.event.rsvp_deadline ?? props.event.starts_at),
)
const full = computed(
  () => !!props.event.capacity && going.value >= props.event.capacity && mine.value !== 'going',
)
const busy = ref(false)
const reasonOpen = ref(false)
const reason = ref('')

async function send(answer: 'going' | 'not_going', why?: string) {
  busy.value = true
  try {
    await attendance.answer(props.event.id, answer, why)
    reasonOpen.value = false
    toast.success(t(answer === 'going' ? 'rsvp.savedGoing' : 'rsvp.savedNotGoing'))
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}

function askReason() {
  reason.value = attendance.mine[props.event.id]?.reason ?? ''
  reasonOpen.value = true
}
</script>

<template>
  <div class="bw-rsvp" :class="`is-${size}`">
    <p v-if="closed" class="bw-rsvp-closed">
      <span v-if="mine" class="bw-badge" :class="mine === 'going' ? 'bw-badge--teal' : 'bw-badge--muted'">
        {{ mine === 'going' ? t('rsvp.youreIn') : t('rsvp.youCant') }}
      </span>
      <span class="small text-muted">{{
        event.status === 'cancelled' ? t('events.cancelled') : t('rsvp.closed')
      }}</span>
    </p>
    <div v-else class="bw-rsvp-buttons" role="group" :aria-label="t('rsvp.question')">
      <button
        type="button"
        class="btn"
        :class="[mine === 'going' ? 'btn-primary' : 'btn-outline-accent']"
        :aria-pressed="mine === 'going'"
        :disabled="busy || full"
        @click="send('going')"
      >
        <i class="bi bi-check-lg me-1" aria-hidden="true"></i>{{ full ? t('rsvp.full') : t('rsvp.going') }}
      </button>
      <button
        type="button"
        class="btn"
        :class="[mine === 'not_going' ? 'btn-light' : 'btn-outline-secondary']"
        :aria-pressed="mine === 'not_going'"
        :disabled="busy"
        @click="askReason"
      >
        {{ t('rsvp.notGoing') }}
      </button>
    </div>

    <BaseDialog v-model:open="reasonOpen" :title="t('rsvp.notGoingTitle', { title: event.title })">
      <form id="reason-form" @submit.prevent="send('not_going', reason)">
        <label for="rsvp-reason" class="form-label">{{ t('rsvp.reason') }}</label>
        <input
          id="rsvp-reason"
          v-model="reason"
          class="form-control"
          maxlength="300"
          :placeholder="t('rsvp.reasonPlaceholder')"
        />
      </form>
      <template #footer>
        <button type="button" class="btn btn-outline-secondary" @click="reasonOpen = false">
          {{ t('common.cancel') }}
        </button>
        <button type="submit" form="reason-form" class="btn btn-primary" :disabled="busy">
          {{ t('rsvp.send') }}
        </button>
      </template>
    </BaseDialog>
  </div>
</template>

<style scoped>
.bw-rsvp-buttons {
  display: flex;
  gap: 0.5rem;
}

.bw-rsvp-buttons .btn {
  flex: 1;
}

.bw-rsvp-buttons .btn {
  white-space: nowrap;
  padding-inline: 0.75rem;
}

.is-lg .btn {
  min-height: 52px;
}

.bw-rsvp-closed {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  margin: 0;
}
</style>
