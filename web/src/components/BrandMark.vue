<script setup lang="ts">
// Logo badge like the website's: gradient rounded square with Bebas initials.
withDefaults(defineProps<{ size?: number }>(), { size: 36 })
</script>

<template>
  <span class="bw-mark" :style="{ width: `${size}px`, height: `${size}px`, fontSize: `${size * 0.5}px` }" aria-hidden="true"
    >BW</span
  >
</template>

<style scoped>
.bw-mark {
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  border-radius: 28%;
  background: linear-gradient(135deg, var(--bw-teal), var(--bw-pink));
  color: #fff;
  font-family: var(--bw-font-display);
  letter-spacing: 0.04em;
  line-height: 1;
}
</style>
