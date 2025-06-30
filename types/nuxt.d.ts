// types/nuxt.d.ts
// TypeScript declarations for Nuxt runtime config

declare module "nuxt/schema" {
  interface RuntimeConfig {
    // Private config (server-side only)
    sendgridApiKey: string;
    directusWebhookSecret: string;
    sendgridUnsubscribeGroupId?: string;
  }

  interface PublicRuntimeConfig {
    // Public config (client + server)
    directusUrl: string;
    siteUrl: string;
    newsletterLogoUrl?: string;
  }
}

export {};
