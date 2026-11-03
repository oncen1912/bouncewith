<script setup lang="ts">
// Website-style page header: small coloured eyebrow + big Bebas title, actions on the right.
defineProps<{ title: string; eyebrow?: string; eyebrowColor?: 'pink' | 'yellow' }>()
</script>

<template>
  <header class="bw-page-header">
    <div class="min-w-0">
      <div v-if="eyebrow" class="section-eyebrow" :class="eyebrowColor">{{ eyebrow }}</div>
      <h1 class="section-title text-truncate">{{ title }}</h1>
    </div>
    <div v-if="$slots.default" class="bw-page-actions">
      <slot />
    </div>
  </header>
</template>

<style scoped>
.bw-page-header {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.bw-page-header > div:first-child {
  flex: 1 1 14rem;
}

.bw-page-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
</style>
