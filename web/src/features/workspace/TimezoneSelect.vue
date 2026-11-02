<script setup lang="ts">
import { computed } from 'vue'

const model = defineModel<string>({ required: true })
defineProps<{ id: string }>()

const zones = computed(() => {
  const all = Intl.supportedValuesOf('timeZone')
  return all.includes(model.value) ? all : [model.value, ...all]
})
</script>

<template>
  <select :id="id" v-model="model" class="form-select">
    <option v-for="zone in zones" :key="zone" :value="zone">{{ zone.replaceAll('_', ' ') }}</option>
  </select>
</template>
