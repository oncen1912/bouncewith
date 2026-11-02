<script setup lang="ts">
defineProps<{ icon: string; title: string; text?: string }>()
</script>

<template>
  <div class="bw-empty">
    <i :class="['bi', icon]" aria-hidden="true"></i>
    <p class="fw-semibold text-body mb-1">{{ title }}</p>
    <p v-if="text" class="mb-0 small">{{ text }}</p>
    <slot />
  </div>
</template>
