export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  modules: ['@nuxtjs/supabase', '@nuxtjs/i18n', '@nuxt/eslint', '@nuxt/test-utils/module'],
  devtools: { enabled: true },
  typescript: { strict: true, typeCheck: false },
  supabase: {
    types: '~~/shared/types/database.types.ts',
    // Auth redirects arrive with F5.
    redirect: false,
  },
  i18n: {
    defaultLocale: 'it',
    strategy: 'prefix_except_default',
    locales: [{ code: 'it', file: 'it.json' }, { code: 'en', file: 'en.json' }],
  },
})
