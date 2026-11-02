<script setup lang="ts">
// Placeholder for M4: renders the workspace slug so the build pipeline and size budget are in place.
defineProps<{ workspace: string; theme?: 'dark' | 'light' }>()
</script>

<template>
  <div class="bw" :data-theme="theme ?? 'dark'">BounceWith · {{ workspace }}</div>
</template>

<style>
.bw {
  font-family: system-ui, sans-serif;
  color: #f0f0f0;
  padding: 1rem;
}
.bw[data-theme='light'] {
  color: #111;
}
</style>
