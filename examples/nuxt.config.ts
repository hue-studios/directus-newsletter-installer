// examples/nuxt.config.ts
// Example Nuxt configuration for newsletter feature

export default defineNuxtConfig({
  devtools: { enabled: true },

  // Runtime configuration for newsletter feature
  runtimeConfig: {
    // Private keys (only available on server-side)
    sendgridApiKey: process.env.SENDGRID_API_KEY || "",
    directusWebhookSecret: process.env.DIRECTUS_WEBHOOK_SECRET || "",
    sendgridUnsubscribeGroupId: process.env.SENDGRID_UNSUBSCRIBE_GROUP_ID,

    // Public keys (exposed to client-side)
    public: {
      directusUrl: process.env.DIRECTUS_URL || "",
      siteUrl: process.env.NUXT_SITE_URL || "",
      newsletterLogoUrl: process.env.NEWSLETTER_LOGO_URL,
    },
  },

  // CSS Framework (if using Tailwind)
  css: ["@/assets/css/main.css"],

  // Modules
  modules: [
    "@nuxtjs/tailwindcss", // Optional: if using Tailwind CSS
    "@vueuse/nuxt", // Optional: if using VueUse
  ],

  // TypeScript configuration
  typescript: {
    typeCheck: true,
  },

  // Server configuration
  nitro: {
    experimental: {
      wasm: true, // Enable if using WASM features
    },
  },

  // Build configuration
  build: {
    transpile: ["@directus/sdk"], // Transpile Directus SDK for compatibility
  },
});
