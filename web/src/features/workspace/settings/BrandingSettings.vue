<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import WorkspaceAvatar from '@/components/WorkspaceAvatar.vue'
import * as api from '../api'
import type { WorkspacePatch, WorkspaceSettings } from '../types'

const props = defineProps<{
  settings: WorkspaceSettings
  save: (patch: WorkspacePatch) => Promise<boolean>
}>()
const { t } = useI18n()

const PRESETS = ['#1BBDBF', '#F01A7F', '#F8B830', '#7C5CFF', '#3DDC84', '#FF6B35']
const accent = ref(props.settings.accent_color ?? '#1BBDBF')
const uploading = ref(false)
const fileInput = ref<HTMLInputElement>()

async function onFile(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  uploading.value = true
  try {
    const url = await api.uploadLogo(props.settings.id, file)
    await props.save({ logo_url: url })
  } catch (e) {
    const message = e instanceof Error ? e.message : ''
    toast.error(t(message === 'logo_type' || message === 'logo_size' ? `settings.${message}` : errorKey(e)))
  } finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

const saveAccent = () => props.save({ accent_color: accent.value.toUpperCase() })
</script>

<template>
  <section class="card card-body" aria-labelledby="set-brand">
    <h2 id="set-brand" class="h5 mb-3">{{ t('settings.branding') }}</h2>

    <div class="d-flex align-items-center gap-3 mb-4">
      <WorkspaceAvatar :workspace="{ ...settings, accent_color: accent }" size="64" />
      <div class="d-flex flex-wrap gap-2">
        <label class="btn btn-outline-light mb-0" :class="{ disabled: uploading }">
          <i class="bi bi-upload me-1" aria-hidden="true"></i>{{ t('settings.uploadLogo') }}
          <input
            ref="fileInput"
            type="file"
            class="visually-hidden"
            accept="image/png,image/jpeg,image/webp"
            :disabled="uploading"
            @change="onFile"
          />
        </label>
        <button
          v-if="settings.logo_url"
          type="button"
          class="btn btn-outline-secondary"
          @click="save({ logo_url: null })"
        >
          {{ t('settings.removeLogo') }}
        </button>
      </div>
    </div>
    <p class="form-text mt-n3 mb-4">{{ t('settings.logoHelp') }}</p>

    <fieldset>
      <legend class="form-label fs-6">{{ t('settings.accent') }}</legend>
      <div class="d-flex flex-wrap align-items-center gap-2">
        <button
          v-for="color in PRESETS"
          :key="color"
          type="button"
          class="bw-swatch"
          :class="{ active: accent.toUpperCase() === color }"
          :style="{ background: color }"
          :aria-label="color"
          :aria-pressed="accent.toUpperCase() === color"
          @click="accent = color"
        ></button>
        <label class="visually-hidden" for="set-accent">{{ t('settings.customColor') }}</label>
        <input id="set-accent" v-model="accent" type="color" class="form-control form-control-color" />
        <button type="button" class="btn btn-primary ms-auto" @click="saveAccent">
          {{ t('common.save') }}
        </button>
      </div>
    </fieldset>
  </section>
</template>

<style scoped>
.bw-swatch {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 3px solid transparent;
}

.bw-swatch.active {
  border-color: var(--bw-text);
}

.bw-swatch:focus-visible {
  outline: 2px solid var(--bw-text);
  outline-offset: 2px;
}

.form-control-color {
  width: 44px;
  height: 44px;
  padding: 4px;
}
</style>
