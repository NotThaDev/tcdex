<script setup lang="ts">
const { t } = useI18n()
useHead({ title: () => t('home.title') })
</script>

<template>
  <main>
    <h1>{{ t('home.title') }}</h1>
    <p>{{ t('home.placeholder') }}</p>
  </main>
</template>
