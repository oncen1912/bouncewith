<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { renderSVG } from 'uqr'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import * as api from '../api'
import type { WorkspaceSettings } from '../types'

const settings = defineModel<WorkspaceSettings>('settings', { required: true })
const { t } = useI18n()

const link = computed(() => `${window.location.origin}/join/${settings.value.join_code}`)
// QR markup is generated locally from our own link, not user HTML
const qr = computed(() => renderSVG(link.value, { border: 2 }))
const qrDownload = computed(() => `data:image/svg+xml;charset=utf-8,${encodeURIComponent(qr.value)}`)
const confirmOpen = ref(false)
const busy = ref(false)

async function copy(text: string) {
  try {
    await navigator.clipboard.writeText(text)
    toast.success(t('settings.copied'))
  } catch {
    toast.error(t('errors.generic'))
  }
}

async function regenerate() {
  busy.value = true
  try {
    settings.value.join_code = await api.regenerateJoinCode(settings.value.id)
    confirmOpen.value = false
    toast.success(t('settings.codeRegenerated'))
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <section class="card card-body" aria-labelledby="set-invite">
    <h2 id="set-invite" class="h5 mb-1">{{ t('settings.invite') }}</h2>
    <p class="small text-muted mb-3">{{ t('settings.inviteHelp') }}</p>

    <div class="row g-3 align-items-center">
      <div class="col-sm-auto text-center">
        <!-- eslint-disable-next-line vue/no-v-html -->
        <div class="bw-qr" role="img" :aria-label="t('settings.qrLabel')" v-html="qr"></div>
        <a :href="qrDownload" :download="`join-${settings.slug}.svg`" class="btn btn-link btn-sm">
          <i class="bi bi-download me-1" aria-hidden="true"></i>{{ t('settings.downloadQr') }}
        </a>
      </div>
      <div class="col">
        <p class="small text-muted mb-1">{{ t('settings.joinCode') }}</p>
        <p class="fs-3 fw-bold font-monospace mb-2" data-testid="join-code">{{ settings.join_code }}</p>
        <div class="d-flex flex-wrap gap-2">
          <button type="button" class="btn btn-outline-light" @click="copy(link)">
            <i class="bi bi-link-45deg me-1" aria-hidden="true"></i>{{ t('settings.copyLink') }}
          </button>
          <button type="button" class="btn btn-outline-light" @click="copy(settings.join_code)">
            <i class="bi bi-clipboard me-1" aria-hidden="true"></i>{{ t('settings.copyCode') }}
          </button>
          <button type="button" class="btn btn-outline-danger" @click="confirmOpen = true">
            <i class="bi bi-arrow-repeat me-1" aria-hidden="true"></i>{{ t('settings.regenerate') }}
          </button>
        </div>
      </div>
    </div>

    <BaseDialog v-model:open="confirmOpen" :title="t('settings.regenerate')">
      <p class="mb-0">{{ t('settings.regenerateConfirm') }}</p>
      <template #footer>
        <button type="button" class="btn btn-outline-secondary" @click="confirmOpen = false">
          {{ t('common.cancel') }}
        </button>
        <button type="button" class="btn btn-danger" :disabled="busy" @click="regenerate">
          {{ t('settings.regenerate') }}
        </button>
      </template>
    </BaseDialog>
  </section>
</template>

<style scoped>
.bw-qr {
  width: 160px;
  background: #fff;
  border-radius: 8px;
  padding: 4px;
}

.bw-qr :deep(svg) {
  display: block;
  width: 100%;
  height: auto;
}
</style>
