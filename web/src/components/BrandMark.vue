<script setup lang="ts">
// The BounceWith ball: pink core, ring in the accent colour (same mark as the favicon).
withDefaults(defineProps<{ size?: number }>(), { size: 32 })
</script>

<template>
  <span class="bw-mark" :style="{ width: `${size}px`, height: `${size}px` }" aria-hidden="true"></span>
</template>

<style scoped>
.bw-mark {
  display: inline-block;
  flex: none;
  border-radius: 50%;
  background: radial-gradient(circle, var(--bw-pink) 0 35%, var(--bw-accent) 36%);
  box-shadow: 0 0 24px color-mix(in srgb, var(--bw-accent) 35%, transparent);
}
</style>
