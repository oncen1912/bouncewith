import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    projects: [
      'web',
      'shared',
      // pure helpers shared by Edge Functions (no Deno APIs)
      {
        test: {
          name: 'functions',
          environment: 'node',
          include: ['supabase/functions/_shared/**/*.spec.ts'],
        },
      },
    ],
  },
})
