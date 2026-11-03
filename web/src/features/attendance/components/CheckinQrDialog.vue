<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { renderSVG } from 'uqr'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import * as api from '../api'

const open = defineModel<boolean>('open', { required: true })
const props = defineProps<{ eventId: string; title: string }>()
const { t } = useI18n()

const MINUTES = 30
const token = ref<string | null>(null)
const expiresAt = ref(0)
const now = ref(Date.now())
const timer = setInterval(() => (now.value = Date.now()), 1000)
onBeforeUnmount(() => clearInterval(timer))

const link = computed(() => (token.value ? `${window.location.origin}/checkin/${token.value}` : ''))
// QR markup is generated locally from our own link
const qr = computed(() => (link.value ? renderSVG(link.value, { border: 2 }) : ''))
const left = computed(() => Math.max(0, Math.round((expiresAt.value - now.value) / 1000)))
const leftLabel = computed(() => `${Math.floor(left.value / 60)}:${String(left.value % 60).padStart(2, '0')}`)

async function create() {
  try {
    token.value = await api.createToken(props.eventId, MINUTES)
    expiresAt.value = Date.now() + MINUTES * 60_000
  } catch (e) {
    toast.error(t(errorKey(e)))
  }
}

watch(open, (o) => o && !token.value && void create(), { immediate: true })
</script>

<template>
  <BaseDialog v-model:open="open" :title="t('attendance.qrTitle')">
    <p class="small text-muted">{{ t('attendance.qrHelp', { title }) }}</p>
    <div v-if="qr" class="text-center">
      <!-- eslint-disable-next-line vue/no-v-html -->
      <div class="bw-qr mx-auto" role="img" :aria-label="t('attendance.qrLabel')" v-html="qr"></div>
      <p class="mt-3 mb-0" aria-live="polite">
        <span v-if="left > 0">{{ t('attendance.qrValid', { time: leftLabel }) }}</span>
        <span v-else class="text-warning">{{ t('attendance.qrExpired') }}</span>
      </p>
    </div>
    <template #footer>
      <button type="button" class="btn btn-outline-light" @click="create">
        <i class="bi bi-arrow-repeat me-1" aria-hidden="true"></i>{{ t('settings.regenerate') }}
      </button>
      <button type="button" class="btn btn-primary" @click="open = false">{{ t('common.close') }}</button>
    </template>
  </BaseDialog>
</template>

<style scoped>
.bw-qr {
  width: min(300px, 70vw);
  background: #fff;
  border-radius: 12px;
  padding: 6px;
}

.bw-qr :deep(svg) {
  display: block;
  width: 100%;
  height: auto;
}
</style>
