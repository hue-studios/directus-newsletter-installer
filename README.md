# Directus Newsletter Feature Installer

A complete newsletter system for Directus 11 with MJML email templates and SendGrid integration. Easily add professional newsletter functionality to existing Directus instances without disrupting current operations.

![Newsletter Feature Demo](https://via.placeholder.com/800x400?text=Newsletter+Feature+Demo)

## ✨ Features

- **🎨 Block-based Email Builder** - Visual MJML block system
- **📧 SendGrid Integration** - Reliable email delivery with tracking
- **📊 Send Analytics** - Track delivery status and performance
- **🎯 Mailing List Management** - Organize subscribers into groups
- **⚡ One-click Sending** - Automated flow with Directus triggers
- **📱 Mobile Responsive** - MJML ensures compatibility across devices
- **🔧 Extensible** - Easy to add custom block types
- **🛡️ Safe Installation** - Non-destructive deployment to existing sites

## 🚀 Quick Start

### One-Command Installation

```bash
# Download and install directly
curl -fsSL https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh | bash -s full https://your-directus-url.com admin@example.com your-password
```

### Manual Installation

```bash
# 1. Clone or download
git clone https://github.com/hue-studios/directus-newsletter-installer.git
cd directus-newsletter-installer

# 2. Set up installation files
./deploy.sh setup

# 3. Install to your Directus instance
./deploy.sh install https://your-directus-url.com admin@example.com your-password
```

## 📦 What Gets Installed

### Directus Collections
- **newsletters** - Main newsletter content and settings
- **newsletter_blocks** - Individual MJML blocks  
- **block_types** - Available block templates (7 included)
- **mailing_lists** - Subscriber group management
- **newsletter_sends** - Delivery tracking and history

### Ready-to-Use Block Types
- **Hero Section** - Title, subtitle, image, and CTA button
- **Text Block** - Rich text content with formatting
- **Image Block** - Images with captions and links
- **Button** - Customizable call-to-action buttons
- **Two Column Layout** - Side-by-side content
- **Spacer** - Vertical spacing control
- **Divider** - Horizontal line separators

### Nuxt.js Integration
- **MJML Compilation** - `/api/newsletter/compile-mjml`
- **Email Sending** - `/api/newsletter/send`
- **Unsubscribe Handling** - Token-based secure unsubscribe
- **Error Tracking** - Comprehensive logging and monitoring

## 🏗️ Installation Guide

### Prerequisites

- Directus 11 instance (running in Docker or standalone)
- Nuxt 3 project
- SendGrid account and API key
- Node.js 16+ on deployment server

### Step 1: Deploy to Directus

Choose your installation method:

**Option A: Direct Installation**
```bash
# SSH into your server
ssh root@your-droplet-ip

# Download and run installer
wget https://raw.githubusercontent.com/hue-studios/directus-newsletter-installer/main/deploy.sh
chmod +x deploy.sh
./deploy.sh full https://your-directus-url.com admin@example.com password
```

**Option B: Docker Container**
```bash
# Run installer from container
docker run --rm --network directus_network \
  yourusername/newsletter-installer:latest \
  https://directus:8055 admin@example.com password
```

### Step 2: Configure Nuxt Project

**Install Dependencies:**
```bash
cd /path/to/your/nuxt/project
npm install mjml @sendgrid/mail handlebars @directus/sdk
npm install -D @types/mjml
```

**Copy Server Endpoints:**
```bash
# Copy from installer directory
cp -r /opt/newsletter-feature/server/ ./server/
```

**Update nuxt.config.ts:**
```typescript
export default defineNuxtConfig({
  runtimeConfig: {
    sendgridApiKey: process.env.SENDGRID_API_KEY,
    directusWebhookSecret: process.env.DIRECTUS_WEBHOOK_SECRET,
    public: {
      directusUrl: process.env.DIRECTUS_URL,
      siteUrl: process.env.NUXT_SITE_URL
    }
  }
})
```

**Configure Environment Variables:**
```env
# .env
DIRECTUS_URL=https://admin.client.com
DIRECTUS_WEBHOOK_SECRET=your-secure-random-string
SENDGRID_API_KEY=SG.your-sendgrid-api-key
NUXT_SITE_URL=https://client.com
```

### Step 3: Complete Directus Setup

1. **Log into Directus Admin**
2. **Go to Flows** → Find "Send Newsletter" flow
3. **Configure Flow Operations**:
   - Add validation operation
   - Add webhook to compile MJML
   - Add webhook to send emails
   - Add status update operations
4. **Test with Sample Newsletter**

## 🎯 Usage

### Creating Your First Newsletter

1. **Go to Content → Newsletters → Create New**
2. **Add Basic Info**:
   - Title: "Welcome Newsletter"
   - Subject: "Welcome to our newsletter!"
   - From Name: "Your Company"
   - From Email: "hello@yourcompany.com"

3. **Add Blocks**:
   - Add a "Hero Section" block
   - Configure title: "Welcome to Our Newsletter"
   - Add a "Text Block" with your content
   - Add a "Button" block for your CTA

4. **Select Mailing Lists**:
   - Choose which subscriber groups to send to

5. **Send Newsletter**:
   - Set status to "Ready to Send"
   - Click "Send Newsletter" button
   - Confirm sending in the popup

### Managing Block Types

**View Available Blocks:**
- Go to Content → Block Types
- See all available MJML templates

**Create Custom Block:**
```javascript
// Example: Custom Quote Block
{
  "name": "Quote Block",
  "slug": "quote", 
  "mjml_template": `
    <mj-section background-color="{{bg_color}}">
      <mj-column>
        <mj-text font-style="italic" font-size="{{font_size}}" align="center">
          "{{quote_text}}"
        </mj-text>
        <mj-text align="center" font-weight="bold">
          — {{author}}
        </mj-text>
      </mj-column>
    </mj-section>
  `,
  "fields_schema": {
    "type": "object",
    "properties": {
      "quote_text": {"type": "string", "title": "Quote Text"},
      "author": {"type": "string", "title": "Author"},
      "bg_color": {"type": "string", "title": "Background Color", "default": "#f8f9fa"},
      "font_size": {"type": "string", "title": "Font Size", "default": "18px"}
    }
  }
}
```

## 🔧 Client Deployment Workflow

### For Agencies Managing Multiple Clients

**1. Prepare Client Environment:**
```bash
# Set up client-specific deployment
CLIENT_NAME="acme-corp"
DIRECTUS_URL="https://acme-admin.com"
ADMIN_EMAIL="admin@acme.com"

# Create client directory
mkdir -p "/opt/clients/$CLIENT_NAME"
cd "/opt/clients/$CLIENT_NAME"
```

**2. Deploy Newsletter Feature:**
```bash
# Run installation
/opt/newsletter-installer/deploy.sh full "$DIRECTUS_URL" "$ADMIN_EMAIL" "$ADMIN_PASSWORD"

# Log deployment
echo "$(date): Newsletter deployed to $CLIENT_NAME" >> /var/log/newsletter-deployments.log
```

**3. Configure Client Nuxt Project:**
```bash
# Copy endpoints to client's Nuxt project
scp -r server/ client-server:/path/to/nuxt/server/

# Install dependencies on client server
ssh client-server "cd /path/to/nuxt && npm install mjml @sendgrid/mail handlebars"

# Restart client services
ssh client-server "docker-compose restart nuxt"
```

**4. Client-Specific Configuration:**
```bash
# Add client's SendGrid API key
echo "SENDGRID_API_KEY=client-sendgrid-key" >> /path/to/client/.env

# Configure client branding in header/footer
# Update MJML templates with client logo and colors
```

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed setup instructions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Deployment Guide](docs/DEPLOYMENT.md) - Client deployment workflows
- [API Reference](docs/API.md) - Server endpoint documentation

## 🛠️ Development

### Local Development Setup

```bash
# Clone repository
git clone https://github.com/hue-studios/directus-newsletter-installer.git
cd directus-newsletter-installer

# Install dependencies
npm install

# Test installer
npm run validate

# Test deployment
./deploy.sh setup
```

### Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-block-type`
3. Commit changes: `git commit -am 'Add new block type'`
4. Push to branch: `git push origin feature/new-block-type`
5. Submit pull request

## 🔍 Troubleshooting

### Common Issues

**"Cannot find module 'mjml'"**
```bash
# Install MJML dependency
npm install mjml @types/mjml
```

**"SendGrid API key is not valid"**
```bash
# Check API key permissions in SendGrid dashboard
# Ensure "Mail Send" permission is enabled
```

**"Directus authentication failed"**
```bash
# Test authentication manually
curl -X POST https://your-directus.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'
```

**"MJML compilation errors"**
```bash
# Check server logs
docker logs your-nuxt-container

# Test MJML endpoint
curl -X POST https://your-site.com/api/newsletter/compile-mjml \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1}'
```

### Getting Help

1. Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Review server logs for errors
3. Test individual components (Directus, SendGrid, MJML)
4. Open an issue with detailed error information

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Support

- 📧 Email: support@youragency.com
- 💬 Issues: [GitHub Issues](https://github.com/hue-studios/directus-newsletter-installer/issues)
- 📖 Docs: [Documentation](docs/)

## 🙏 Acknowledgments

- [Directus](https://directus.io/) - Headless CMS platform
- [MJML](https://mjml.io/) - Email framework
- [SendGrid](https://sendgrid.com/) - Email delivery service
- [Nuxt.js](https://nuxt.com/) - Vue.js framework

---

**Ready to add powerful newsletter functionality to your Directus projects? Get started with the one-command installation above!** 🚀