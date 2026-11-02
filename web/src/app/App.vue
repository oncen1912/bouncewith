<script setup lang="ts">
import { Toaster } from 'vue-sonner'
</script>

<template>
  <RouterView />
  <Toaster theme="dark" position="top-center" rich-colors close-button />
</template>
