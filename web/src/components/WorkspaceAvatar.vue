<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    workspace: { name: string; logo_url: string | null; accent_color: string | null }
    size?: string
  }>(),
  { size: '40' },
)
const initials = computed(() =>
  props.workspace.name
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() ?? '')
    .join(''),
)
</script>

<template>
  <img
    v-if="workspace.logo_url"
    :src="workspace.logo_url"
    alt=""
    class="bw-avatar"
    :style="{ width: `${size}px`, height: `${size}px` }"
  />
  <span
    v-else
    class="bw-avatar bw-avatar-initials"
    aria-hidden="true"
    :style="{
      width: `${size}px`,
      height: `${size}px`,
      fontSize: `${Number(size) * 0.4}px`,
      background: workspace.accent_color ?? 'var(--bw-accent)',
    }"
    >{{ initials }}</span
  >
</template>

<style scoped>
.bw-avatar {
  flex: none;
  border-radius: 30%;
  object-fit: cover;
}

.bw-avatar-initials {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #000;
  font-weight: 700;
}
</style>
