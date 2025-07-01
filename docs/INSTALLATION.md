# Installation Guide

Complete step-by-step guide for installing the Directus Newsletter Feature on existing Directus 11 instances with separate frontend integration.

## 🚀 Quick Start (5 minutes)

For those who want to get started immediately:

```bash
# 1. Full setup and install in one command (recommended)
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s full \
  https://admin.theagency-ny.com admin@example.com password https://theagency-ny.com

# 2. Copy frontend files to your Nuxt project (created in /opt/newsletter-feature/)
cp -r /opt/newsletter-feature/frontend-integration/server/ /path/to/your/nuxt/project/server/
cp -r /opt/newsletter-feature/frontend-integration/types/ /path/to/your/nuxt/project/types/

# 3. Install dependencies & configure environment
cd /path/to/your/nuxt/project
npm install mjml @sendgrid/mail handlebars @directus/sdk

# 4. Follow flow setup guide below
```

Then continue with detailed instructions for production setup...

## Prerequisites

Before starting the installation, ensure you have:

- ✅ **Directus 11** instance running (Docker or standalone)
- ✅ **Nuxt 3** project with server-side rendering enabled
- ✅ **SendGrid** account with API key (for email sending)
- ✅ **Node.js 16+** on deployment server
- ✅ **Admin access** to Directus instance
- ✅ **SSH access** to server (for remote installations)
- ✅ **Separate frontend domain** (recommended for production)

## Architecture Overview

This installation creates:
- **Directus Collections** - Installed on your Directus server
- **Frontend Integration** - Separate package for your Nuxt project
- **Flow Configuration** - Automated workflow in Directus (optional)

## Installation Methods

### Method 1: One-Command Installation (Recommended)

The fastest way to install the newsletter feature:

```bash
# Full setup and install (recommended for new installations)
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s full \
  https://admin.theagency-ny.com admin@example.com password https://theagency-ny.com

# Install to Directus only (manual flow setup)
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s install \
  https://admin.theagency-ny.com admin@example.com password

# Install with frontend URL for automated flow setup
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s install \
  https://admin.theagency-ny.com admin@example.com password https://theagency-ny.com
```

### Method 2: Step-by-Step Installation

For more control over the installation process:

```bash
# 1. Download and setup installation files
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s setup

# 2. Install to your Directus instance
cd /opt/newsletter-feature  # or your chosen directory
./deploy.sh install https://admin.theagency-ny.com admin@example.com password https://theagency-ny.com

# Or use the full command
./deploy.sh full https://admin.theagency-ny.com admin@example.com password https://theagency-ny.com
```

### Method 3: Manual Download and Installation

For complete control:

```bash
# 1. Create installation directory
mkdir -p /opt/newsletter-installation
cd /opt/newsletter-installation

# 2. Download files
curl -o deploy.sh https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh
chmod +x deploy.sh

# 3. Setup and install
./deploy.sh setup
./deploy.sh install https://admin.theagency-ny.com admin@example.com password
```

### Method 4: Custom Directory Installation

If you don't have permissions for `/opt/newsletter-feature`:

```bash
# Set custom installation directory
NEWSLETTER_DEPLOY_DIR=~/newsletter-feature curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s full \
  https://admin.theagency-ny.com admin@example.com password https://theagency-ny.com
```

## Step-by-Step Installation

### Step 1: Backup Your Database

**Critical**: Always backup before installation!

```bash
# For PostgreSQL
docker exec postgres-container pg_dump -U directus directus > newsletter-backup-$(date +%Y%m%d).sql

# For MySQL
docker exec mysql-container mysqldump -u directus -p directus > newsletter-backup-$(date +%Y%m%d).sql

# Or use the included backup script (if available)
./scripts/backup-database.sh
```

### Step 2: Install Newsletter Collections to Directus

#### Option A: Full Installation (Recommended)

```bash
# This sets up everything and creates collections with frontend integration
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s full \
  https://admin.theagency-ny.com \
  admin@example.com \
  password \
  https://theagency-ny.com
```

#### Option B: Direct Installation with Frontend URL

```bash
# This creates collections AND prepares flow with your frontend URLs
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s install \
  https://admin.theagency-ny.com \
  admin@example.com \
  password \
  https://theagency-ny.com
```

#### Option C: Directus-Only Installation

```bash
# This only creates collections (manual flow setup required)
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s install \
  https://admin.theagency-ny.com \
  admin@example.com \
  password
```

**What gets installed:**
- ✅ 5 Collections: newsletters, newsletter_blocks, block_types, mailing_lists, newsletter_sends
- ✅ 5 Starter Block Types: Hero, Text, Image, Button, Divider
- ✅ Complete relationships between collections
- ✅ Basic flow structure (if frontend URL provided)
- ✅ Frontend integration package (created in deployment directory)

### Step 3: Integrate with Your Nuxt Frontend

#### Copy Frontend Integration Package

After installation, you'll find a `frontend-integration/` folder in your deployment directory:

```bash
# Default location (if using /opt/newsletter-feature)
cp -r /opt/newsletter-feature/frontend-integration/server/ /path/to/your/nuxt/project/server/
cp -r /opt/newsletter-feature/frontend-integration/types/ /path/to/your/nuxt/project/types/

# If you used a custom directory
cp -r ~/newsletter-feature/frontend-integration/server/ /path/to/your/nuxt/project/server/
cp -r ~/newsletter-feature/frontend-integration/types/ /path/to/your/nuxt/project/types/

# Check the integration README for detailed instructions
cat /opt/newsletter-feature/frontend-integration/README.md
```

#### Install Required Dependencies

```bash
cd /path/to/your/nuxt/project
npm install mjml @sendgrid/mail handlebars @directus/sdk
npm install -D @types/mjml
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
DIRECTUS_URL=https://admin.theagency-ny.com
DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret-here

# SendGrid Configuration  
SENDGRID_API_KEY=SG.your-sendgrid-api-key-here
SENDGRID_UNSUBSCRIBE_GROUP_ID=12345

# Site Configuration
NUXT_SITE_URL=https://theagency-ny.com
```

#### Test Frontend Endpoints

```bash
# Start your Nuxt development server
npm run dev

# Test MJML compilation endpoint
curl -X POST http://localhost:3000/api/newsletter/compile-mjml \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1}'

# Expected response: {"success": true, "message": "MJML compiled successfully"}
```

### Step 4: Configure Directus Flow

The newsletter feature uses a Directus flow to automate the sending process. You have two options:

#### Option A: Complete Automated Flow Setup

If you provided a frontend URL during installation, a basic flow was created. Complete the setup:

1. **Log into Directus Admin**
2. **Go to Settings → Flows → Send Newsletter**
3. **Verify all operations are connected correctly**
4. **Test the flow with a sample newsletter**

#### Option B: Manual Flow Creation

For complete control or if automatic creation failed:

**📖 [Follow the detailed Flow Setup Guide](FLOW_SETUP.md)**

The manual setup covers:
- Step-by-step flow creation with all operations
- Webhook configurations with your actual URLs
- Testing and troubleshooting steps
- Advanced configurations for multiple mailing lists

**📋 [Quick Flow Reference](../examples/flow-quick-reference.md)** for copy-paste commands

### Step 5: Restart and Verify Services

#### For Docker Compose

```bash
# Restart Directus to recognize new collections
docker-compose restart directus

# Restart your Nuxt application
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

#### Verification Checklist

After installation and restart, verify:

- [ ] Newsletter collections exist in Directus admin
- [ ] Block types are populated (5 starter types)
- [ ] Frontend integration files copied to Nuxt project
- [ ] Nuxt endpoints respond correctly
- [ ] Environment variables are loaded
- [ ] Directus flow is configured and active
- [ ] Test newsletter compiles MJML successfully
- [ ] Test email can be sent

## Environment-Specific Configuration

### Development Environment

```env
DIRECTUS_URL=http://localhost:8055
NUXT_SITE_URL=http://localhost:3000
DIRECTUS_WEBHOOK_SECRET=dev-secret-123
SENDGRID_API_KEY=SG.development-key
```

### Staging Environment

```env
DIRECTUS_URL=https://staging-admin.theagency-ny.com
NUXT_SITE_URL=https://staging.theagency-ny.com
DIRECTUS_WEBHOOK_SECRET=staging-secret-456
SENDGRID_API_KEY=SG.staging-key
```

### Production Environment

```env
DIRECTUS_URL=https://admin.theagency-ny.com
NUXT_SITE_URL=https://theagency-ny.com
DIRECTUS_WEBHOOK_SECRET=production-secret-789
SENDGRID_API_KEY=SG.production-key
```

## SendGrid Configuration

### API Key Setup

1. **Log into [SendGrid Console](https://app.sendgrid.com/)**
2. **Go to Settings → API Keys**
3. **Create new API key** with **Mail Send** permissions
4. **Copy the API key** to your `.env` file

### Domain Authentication (Recommended)

1. **Go to Settings → Sender Authentication**
2. **Click "Authenticate Your Domain"**
3. **Follow DNS setup instructions**
4. **Verify domain authentication**

### Unsubscribe Groups (Optional)

1. **Go to Marketing → Unsubscribe Groups**
2. **Create a group** for your newsletters
3. **Note the Group ID** for your `.env` file

## Testing Your Installation

### Test 1: Verify Collections

1. **Log into Directus Admin**
2. **Go to Content → Block Types**
3. **Verify 5 starter block types exist**
4. **Go to Content → Newsletters**  
5. **Create a test newsletter**

### Test 2: Test MJML Compilation

```bash
# Create a test newsletter first, then:
curl -X POST https://theagency-ny.com/api/newsletter/compile-mjml \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1}'
```

**Expected response:**
```json
{
  "success": true,
  "message": "MJML compiled successfully"
}
```

### Test 3: Test Complete Flow

1. **Create a test newsletter** with blocks
2. **Create a test mailing list** with your email
3. **Set newsletter status** to "Ready to Send"
4. **Click "Send Newsletter"** button
5. **Check your email** for the test newsletter

## Troubleshooting Common Issues

### Installation Directory Issues

**Symptoms:**
- Permission denied errors
- Cannot write to `/opt/newsletter-feature`

**Solutions:**
```bash
# Use custom directory
NEWSLETTER_DEPLOY_DIR=~/newsletter-feature curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s setup

# Or create directory with proper permissions
sudo mkdir -p /opt/newsletter-feature
sudo chown $(whoami) /opt/newsletter-feature

# Or run with sudo (not recommended for production)
sudo curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s full https://admin.theagency-ny.com admin@example.com password
```

### Collections Not Created

**Symptoms:**
- No newsletter collections in Directus admin
- Authentication errors during installation

**Solutions:**
```bash
# Test Directus connection manually
curl -X POST https://admin.theagency-ny.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'

# Check Directus health
curl -I https://admin.theagency-ny.com/server/health

# Verify admin credentials in Directus admin panel
```

### Frontend Integration Files Missing

**Symptoms:**
- No `frontend-integration/` folder found
- Cannot copy files to Nuxt project

**Solutions:**
```bash
# Check if files were created in deployment directory
ls -la /opt/newsletter-feature/frontend-integration/

# If using custom directory, check there
ls -la ~/newsletter-feature/frontend-integration/

# Re-run setup if needed
./deploy.sh setup
```

### Frontend Endpoints Not Working

**Symptoms:**
- 404 errors on `/api/newsletter/*` endpoints
- Module not found errors

**Solutions:**
```bash
# Verify files were copied correctly
ls -la /path/to/nuxt/server/api/newsletter/

# Check dependencies are installed
npm list mjml @sendgrid/mail handlebars

# Verify file content was copied properly
cat /path/to/nuxt/server/api/newsletter/compile-mjml.post.ts

# Restart Nuxt development server
npm run dev
```

### Flow Not Triggering

**Symptoms:**
- "Send Newsletter" button doesn't appear
- Flow exists but doesn't execute

**Solutions:**
- **Check flow status** is "Active" in Directus admin
- **Verify user permissions** for flow execution
- **Check newsletter status** is "Ready to Send"
- **Review flow operations** for correct connections

### Webhook Failures

**Symptoms:**
- Flow executes but webhooks fail
- Compilation or sending errors

**Solutions:**
```bash
# Test webhook endpoints manually
curl -X POST https://theagency-ny.com/api/newsletter/compile-mjml \
  -H "Authorization: Bearer your-webhook-secret" \
  -H "Content-Type: application/json" \
  -d '{"newsletter_id": 1}'

# Check webhook secret matches
echo $DIRECTUS_WEBHOOK_SECRET

# Verify frontend is accessible from Directus server
curl -I https://theagency-ny.com
```

### SendGrid Errors

**Symptoms:**
- Email sending fails
- "Invalid API key" errors

**Solutions:**
- **Verify API key** in SendGrid dashboard
- **Check API key permissions** (needs "Mail Send")
- **Test API key** manually:

```bash
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [{"to": [{"email": "test@example.com"}]}],
    "from": {"email": "from@example.com"},
    "subject": "Test",
    "content": [{"type": "text/plain", "value": "Test email"}]
  }'
```

## Advanced Configuration

### Multiple Environments

For agencies managing multiple clients:

```bash
# Create environment-specific configurations
CLIENT_NAME="theagency"
DIRECTUS_URL="https://admin.theagency-ny.com"

# Deploy with client-specific settings
./deploy.sh full "$DIRECTUS_URL" "$ADMIN_EMAIL" "$ADMIN_PASSWORD" "https://theagency-ny.com"
```

### Custom Block Types

Add your own MJML block types:

1. **Go to Content → Block Types in Directus**
2. **Create new block type** with MJML template
3. **Define fields schema** for configuration options
4. **Test with sample newsletter**

### Performance Optimization

For large mailing lists:

- **Configure batching** in send endpoint
- **Set up rate limiting** for SendGrid API
- **Monitor sending performance** in newsletter_sends collection

## Rollback Instructions

If you need to remove the newsletter feature:

```bash
# Use the rollback script (if available)
./scripts/rollback.sh full https://admin.theagency-ny.com admin@example.com password /path/to/nuxt

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

1. **📝 Create Your First Newsletter**
   - Use the starter block types
   - Test MJML compilation
   - Send to a test mailing list

2. **🎨 Customize Block Types**
   - Add your own MJML templates
   - Create branded blocks
   - Build reusable components

3. **📊 Set Up Analytics**
   - Monitor sending performance
   - Track newsletter engagement
   - Review error logs

4. **🔧 Production Optimization**
   - Configure proper SendGrid settings
   - Set up monitoring and alerts
   - Optimize for your sending volume

5. **👥 Train Your Team**
   - Document newsletter creation process
   - Set up user permissions
   - Create style guidelines

## Support

If you encounter issues during installation:

1. **Check this guide** for common solutions
2. **Review [Flow Setup Guide](FLOW_SETUP.md)** for flow-specific issues
3. **Check [Troubleshooting Guide](TROUBLESHOOTING.md)** for detailed debugging
4. **Use [Quick Flow Reference](../examples/flow-quick-reference.md)** for copy-paste commands
5. **Test components individually** (Directus, frontend, SendGrid)
6. **Open an issue** with detailed error information

For urgent support, contact: support@youragency.com

---

**Ready to add powerful newsletter functionality to your Directus projects?** Start with the one-command installation above and follow this guide step-by-step! 🚀