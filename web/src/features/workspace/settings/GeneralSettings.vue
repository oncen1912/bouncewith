<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import TimezoneSelect from '../TimezoneSelect.vue'
import { WORKSPACE_TYPES, type WorkspacePatch, type WorkspaceSettings } from '../types'

const props = defineProps<{
  settings: WorkspaceSettings
  save: (patch: WorkspacePatch) => Promise<boolean>
}>()
const { t } = useI18n()

const form = reactive({
  name: props.settings.name,
  type: props.settings.type,
  timezone: props.settings.timezone,
  require_approval: props.settings.require_approval,
  allow_self_absence: props.settings.allow_self_absence,
})
const busy = ref(false)

async function submit() {
  busy.value = true
  await props.save({ ...form, name: form.name.trim() })
  busy.value = false
}
</script>

<template>
  <section class="card card-body" aria-labelledby="set-general">
    <h2 id="set-general" class="h5 mb-3">{{ t('settings.general') }}</h2>
    <form class="d-grid gap-3" @submit.prevent="submit">
      <div>
        <label for="set-name" class="form-label">{{ t('settings.name') }}</label>
        <input id="set-name" v-model="form.name" class="form-control" minlength="2" maxlength="80" required />
      </div>
      <div class="row g-3">
        <div class="col-sm-6">
          <label for="set-type" class="form-label">{{ t('settings.type') }}</label>
          <select id="set-type" v-model="form.type" class="form-select">
            <option v-for="value in WORKSPACE_TYPES" :key="value" :value="value">
              {{ t(`workspaceTypes.${value}`) }}
            </option>
          </select>
        </div>
        <div class="col-sm-6">
          <label for="set-tz" class="form-label">{{ t('settings.timezone') }}</label>
          <TimezoneSelect id="set-tz" v-model="form.timezone" />
        </div>
      </div>
      <div class="form-check form-switch">
        <input
          id="set-approval"
          v-model="form.require_approval"
          class="form-check-input"
          type="checkbox"
          role="switch"
        />
        <label class="form-check-label" for="set-approval">{{ t('settings.requireApproval') }}</label>
        <div class="form-text">{{ t('settings.requireApprovalHelp') }}</div>
      </div>
      <div class="form-check form-switch">
        <input
          id="set-absence"
          v-model="form.allow_self_absence"
          class="form-check-input"
          type="checkbox"
          role="switch"
        />
        <label class="form-check-label" for="set-absence">{{ t('settings.allowSelfAbsence') }}</label>
        <div class="form-text">{{ t('settings.allowSelfAbsenceHelp') }}</div>
      </div>
      <div class="text-end">
        <button type="submit" class="btn btn-primary" :disabled="busy">{{ t('common.save') }}</button>
      </div>
    </form>
  </section>
</template>
