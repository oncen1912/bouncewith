<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { DEFAULT_TIMEZONE } from '@bouncewith/shared'
import { errorKey } from '@/app/errors'
import TimezoneSelect from './TimezoneSelect.vue'
import * as api from './api'
import { useWorkspaceStore } from './store'
import { SLUG_PATTERN, slugify } from './slug'
import { WORKSPACE_TYPES, type WorkspaceType } from './types'

const { t } = useI18n()
const router = useRouter()
const workspaces = useWorkspaceStore()

const name = ref('')
const slug = ref('')
const slugEdited = ref(false)
const type = ref<WorkspaceType>('dance')
const timezone = ref(DEFAULT_TIMEZONE)
const busy = ref(false)

watch(name, (value) => {
  if (!slugEdited.value) slug.value = slugify(value)
})

async function submit() {
  busy.value = true
  try {
    await api.createWorkspace(name.value.trim(), slug.value, type.value, timezone.value)
    await workspaces.load(true)
    toast.success(t('createWorkspace.created'))
    await router.replace({ name: 'home', params: { slug: slug.value } })
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <h1 class="h3 mb-4">{{ t('createWorkspace.title') }}</h1>

  <form class="card card-body d-grid gap-3" style="max-width: 560px" @submit.prevent="submit">
    <div>
      <label for="ws-name" class="form-label">{{ t('settings.name') }}</label>
      <input id="ws-name" v-model="name" class="form-control" minlength="2" maxlength="80" required />
    </div>

    <div>
      <label for="ws-slug" class="form-label">{{ t('createWorkspace.slug') }}</label>
      <div class="input-group">
        <span class="input-group-text">/w/</span>
        <input
          id="ws-slug"
          v-model="slug"
          class="form-control"
          :pattern="SLUG_PATTERN"
          maxlength="40"
          autocapitalize="off"
          spellcheck="false"
          required
          aria-describedby="ws-slug-help"
          @input="slugEdited = true"
        />
      </div>
      <div id="ws-slug-help" class="form-text">{{ t('createWorkspace.slugHelp') }}</div>
    </div>

    <div>
      <label for="ws-type" class="form-label">{{ t('settings.type') }}</label>
      <select id="ws-type" v-model="type" class="form-select">
        <option v-for="value in WORKSPACE_TYPES" :key="value" :value="value">
          {{ t(`workspaceTypes.${value}`) }}
        </option>
      </select>
    </div>

    <div>
      <label for="ws-tz" class="form-label">{{ t('settings.timezone') }}</label>
      <TimezoneSelect id="ws-tz" v-model="timezone" />
    </div>

    <div class="d-flex gap-2 justify-content-end">
      <RouterLink :to="{ name: 'workspaces' }" class="btn btn-outline-secondary">{{
        t('common.cancel')
      }}</RouterLink>
      <button type="submit" class="btn btn-primary" :disabled="busy">
        {{ t('createWorkspace.submit') }}
      </button>
    </div>
  </form>
</template>
