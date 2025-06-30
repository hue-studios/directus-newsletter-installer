# Installation Guide

Complete step-by-step guide for installing the Directus Newsletter Feature on existing Directus 11 instances.

## Prerequisites

Before starting the installation, ensure you have:

- ✅ **Directus 11** instance running (Docker or standalone)
- ✅ **Nuxt 3** project with server-side rendering enabled
- ✅ **SendGrid** account with API key
- ✅ **Node.js 16+** on deployment server
- ✅ **Admin access** to Directus instance
- ✅ **SSH access** to server (for remote installations)

## Installation Methods

### Method 1: One-Command Installation (Recommended)

The fastest way to install the newsletter feature:

```bash
# Download and install directly
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s full https://your-directus-url.com admin@example.com your-password
```

### Method 2: Manual Installation

For more control over the installation process:

```bash
# 1. Download the installer
git clone https://github.com/hue-studios/directus-newsletter-installer.git
cd directus-newsletter-installer

# 2. Set up installation files
./deploy.sh setup

# 3. Install to your Directus instance
./deploy.sh install https://your-directus-url.com admin@example.com your-password
```

### Method 3: Docker Container Installation

For containerized environments:

```bash
# Build installer image
docker build -t newsletter-installer .

# Run installation
docker run --rm --network your-directus-network \
  newsletter-installer \
  https://directus:8055 admin@example.com password
```

## Step-by-Step Installation

### Step 1: Backup Your Database

**Critical**: Always backup before installation!

```bash
# Use included backup script
./scripts/backup-database.sh

# Or manual backup (PostgreSQL)
docker exec postgres-container pg_dump -U directus directus > backup.sql

# Or manual backup (MySQL)
docker exec mysql-container mysqldump -u directus -p directus > backup.sql
```

### Step 2: Install Newsletter Feature to Directus

#### Option A: Using Deploy Script

```bash
# SSH into your server
ssh root@your-droplet-ip

# Download installer
wget https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh
chmod +x deploy.sh

# Run installation
./deploy.sh full https://your-directus-url.com admin@example.com password
```

#### Option B: Manual Node.js Installation

```bash
# Create installation directory
mkdir -p /opt/newsletter-installation
cd /opt/newsletter-installation

# Create package.json
cat > package.json << 'EOF'
{
  "type": "module",
  "dependencies": {
    "@directus/sdk": "^17.0.0"
  }
}
EOF

# Install dependencies
npm install

# Download and run installer
curl -o newsletter-installer.js https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/newsletter-installer.js
node newsletter-installer.js https://your-directus-url.com admin@example.com password
```

### Step 3: Configure Nuxt.js Project

#### Install Required Dependencies

```bash
cd /path/to/your/nuxt/project
npm install mjml @sendgrid/mail handlebars @directus/sdk
npm install -D @types/mjml
```

#### Copy Server Endpoints

```bash
# Copy endpoints from installer
cp -r /opt/newsletter-installation/server/ ./server/

# Or download directly
mkdir -p server/api/newsletter
curl -o server/api/newsletter/compile-mjml.post.ts https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/server/api/newsletter/compile-mjml.post.ts
curl -o server/api/newsletter/send.post.ts https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/server/api/newsletter/send.post.ts
```

#### Update Nuxt Configuration

Add to your `nuxt.config.ts`:

```typescript
export default defineNuxtConfig({
  runtimeConfig: {
    // Private keys (server-side only)
    sendgridApiKey: process.env.SENDGRID_API_KEY,
    directusWebhookSecret: process.env.DIRECTUS_WEBHOOK_SECRET,
    sendgridUnsubscribeGroupId: process.env.SENDGRID_UNSUBSCRIBE_GROUP_ID,
    
    // Public keys (client + server)
    public: {
      directusUrl: process.env.DIRECTUS_URL,
      siteUrl: process.env.NUXT_SITE_URL
    }
  },

  // Transpile Directus SDK for compatibility
  build: {
    transpile: ['@directus/sdk']
  }
})
```

#### Configure Environment Variables

Create or update your `.env` file:

```env
# Directus Configuration
DIRECTUS_URL=https://admin.yoursite.com
DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret-here

# SendGrid Configuration
SENDGRID_API_KEY=SG.your-sendgrid-api-key-here
SENDGRID_UNSUBSCRIBE_GROUP_ID=12345

# Site Configuration
NUXT_SITE_URL=https://yoursite.com
```

#### Add TypeScript Declarations (Optional)

Create `types/nuxt.d.ts`:

```typescript
declare module 'nuxt/schema' {
  interface RuntimeConfig {
    sendgridApiKey: string
    directusWebhookSecret: string
    sendgridUnsubscribeGroupId?: string
  }
  
  interface PublicRuntimeConfig {
    directusUrl: string
    siteUrl: string
  }
}

export {}
```

### Step 4: Configure Directus Flow

#### Access Directus Admin

1. Log into your Directus Admin panel
2. Navigate to **Settings** → **Flows**
3. Find the "Send Newsletter" flow

#### Configure Flow Operations

The installer creates a basic flow, but you need to add operations:

1. **Validation Operation**
   - Type: Condition
   - Filter: Newsletter status = "ready" AND blocks exist AND mailing lists exist

2. **MJML Compilation Operation**
   - Type: Webhook
   - URL: `https://your-site.com/api/newsletter/compile-mjml`
   - Method: POST
   - Headers: `Authorization: Bearer your-webhook-secret`
   - Body: `{"newsletter_id": "{{$trigger.body.keys[0]}}"}`

3. **Create Send Records Operation**
   - Type: Create Items
   - Collection: newsletter_sends
   - Data: Map newsletter and mailing list data

4. **Send Emails Operation**
   - Type: Webhook
   - URL: `https://your-site.com/api/newsletter/send`
   - Method: POST
   - Headers: `Authorization: Bearer your-webhook-secret`
   - Body: Newsletter and send record data

5. **Update Status Operation**
   - Type: Update Items
   - Collection: newsletters
   - Set status to "sent"

### Step 5: Restart Services

#### For Docker Compose

```bash
# Restart Directus to recognize new collections
docker-compose restart directus

# Restart Nuxt to load new endpoints
docker-compose restart nuxt

# Or restart entire stack
docker-compose down && docker-compose up -d
```

#### For Standalone Services

```bash
# Restart Directus service
systemctl restart directus

# Restart Nuxt/Node.js application
pm2 restart nuxt-app
```

### Step 6: Test Installation

#### Test Directus Collections

1. Log into Directus Admin
2. Go to **Content** → **Block Types**
3. Verify starter block types are present
4. Go to **Content** → **Newsletters**
5. Create a test newsletter

#### Test MJML Compilation

```bash
# Test compilation endpoint
curl -X POST https://your-site.com/api/newsletter/compile-mjml \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1}'
```

Expected response:
```json
{
  "success": true,
  "message": "MJML compiled successfully"
}
```

#### Test Email Sending

Create a test mailing list with your email and send a test newsletter.

## Environment-Specific Configuration

### Development Environment

```env
DIRECTUS_URL=http://localhost:8055
NUXT_SITE_URL=http://localhost:3000
DIRECTUS_WEBHOOK_SECRET=dev-secret-123
```

### Staging Environment

```env
DIRECTUS_URL=https://staging-admin.yoursite.com
NUXT_SITE_URL=https://staging.yoursite.com
DIRECTUS_WEBHOOK_SECRET=staging-secret-456
```

### Production Environment

```env
DIRECTUS_URL=https://admin.yoursite.com
NUXT_SITE_URL=https://yoursite.com
DIRECTUS_WEBHOOK_SECRET=production-secret-789
```

## SendGrid Configuration

### API Key Setup

1. Log into [SendGrid Console](https://app.sendgrid.com/)
2. Go to **Settings** → **API Keys**
3. Create new API key with **Mail Send** permissions
4. Copy the API key to your `.env` file

### Domain Authentication (Recommended)

1. Go to **Settings** → **Sender Authentication**
2. Click **Authenticate Your Domain**
3. Follow DNS setup instructions
4. Verify domain authentication

### Unsubscribe Groups (Optional)

1. Go to **Marketing** → **Unsubscribe Groups**
2. Create a group for your newsletters
3. Note the Group ID for your `.env` file

## Troubleshooting Installation

### Common Issues

#### "Authentication failed"
```bash
# Verify Directus credentials
curl -X POST https://your-directus.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'
```

#### "Cannot find module 'mjml'"
```bash
# Install missing dependencies
npm install mjml @sendgrid/mail handlebars
```

#### "Collections already exist"
- The installer safely skips existing collections
- Check Directus admin to verify installation

#### "Webhook endpoints not accessible"
```bash
# Test endpoint accessibility
curl -I https://your-site.com/api/newsletter/compile-mjml
```

### Database Connection Issues

#### PostgreSQL
```bash
# Test database connection
docker exec postgres-container psql -U directus -d directus -c "SELECT version();"
```

#### MySQL
```bash
# Test database connection
docker exec mysql-container mysql -u directus -p -e "SELECT VERSION();"
```

### Verification Checklist

After installation, verify:

- [ ] Newsletter collections exist in Directus
- [ ] Block types are populated
- [ ] Nuxt endpoints respond correctly
- [ ] Environment variables are set
- [ ] Directus flow is configured
- [ ] Test newsletter compiles MJML
- [ ] Test email sends successfully

## Rollback Instructions

If you need to remove the newsletter feature:

```bash
# Use included rollback script
./scripts/rollback.sh full https://your-directus-url.com admin@example.com password /path/to/nuxt

# Or manual database cleanup
# Connect to your database and run:
DROP TABLE IF EXISTS newsletter_sends CASCADE;
DROP TABLE IF EXISTS newsletter_blocks CASCADE;
DROP TABLE IF EXISTS newsletters CASCADE;
DROP TABLE IF EXISTS mailing_lists CASCADE;
DROP TABLE IF EXISTS block_types CASCADE;
```

## Next Steps

After successful installation:

1. **Customize Block Types** - Add your own MJML templates
2. **Brand Customization** - Update header/footer templates
3. **Import Subscribers** - Add existing email lists
4. **Create Templates** - Build reusable newsletter templates
5. **Set Up Monitoring** - Track email performance
6. **Train Users** - Document newsletter creation process

## Support

If you encounter issues during installation:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review server logs for errors
3. Test components individually
4. Open an issue with detailed error information

For urgent support, contact: support@youragency.com