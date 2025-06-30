#!/bin/bash

# Directus Newsletter Feature - Deployment Script
# This script downloads and installs the newsletter feature on existing Directus instances

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEPLOYMENT_DIR="${NEWSLETTER_DEPLOY_DIR:-/opt/newsletter-feature}"
VERSION="1.0.0"

# Check if we can write to the deployment directory
check_permissions() {
    local test_dir="$1"
    local parent_dir=$(dirname "$test_dir")
    
    # If directory exists and is writable, use it
    if [ -d "$test_dir" ] && [ -w "$test_dir" ]; then
        return 0
    fi
    
    # If parent directory is writable, we can create it
    if [ -w "$parent_dir" ]; then
        return 0
    fi
    
    # Check if we're root
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi
    
    return 1
}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate URL
validate_url() {
    if [[ $1 =~ ^https?://[^[:space:]]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to test Directus connection
test_directus_connection() {
    local url=$1
    local health_endpoint="${url}/server/health"
    
    print_status "Testing connection to Directus at $url..."
    
    if command_exists curl; then
        if curl -s --max-time 10 "$health_endpoint" > /dev/null; then
            print_success "Directus is accessible"
            return 0
        else
            print_error "Could not connect to Directus at $health_endpoint"
            return 1
        fi
    else
        print_warning "curl not found, skipping connection test"
        return 0
    fi
}

# Function to create deployment directory
setup_deployment_dir() {
    print_status "Setting up deployment directory..."
    
    # Check if we can use the default directory
    if ! check_permissions "$DEPLOYMENT_DIR"; then
        print_warning "Cannot write to $DEPLOYMENT_DIR (permission denied)"
        
        # Try alternative directories
        local alternatives=(
            "$HOME/newsletter-feature"
            "/tmp/newsletter-feature"
            "$(pwd)/newsletter-feature"
        )
        
        for alt_dir in "${alternatives[@]}"; do
            if check_permissions "$alt_dir" || check_permissions "$(dirname "$alt_dir")"; then
                print_status "Using alternative directory: $alt_dir"
                DEPLOYMENT_DIR="$alt_dir"
                break
            fi
        done
        
        # If still no writable directory found
        if ! check_permissions "$DEPLOYMENT_DIR"; then
            print_error "No writable directory found. Try one of these solutions:"
            echo "1. Run with sudo: curl ... | sudo bash -s ..."
            echo "2. Set custom directory: NEWSLETTER_DEPLOY_DIR=~/newsletter curl ... | bash -s ..."
            echo "3. Create directory first: sudo mkdir -p /opt/newsletter-feature && sudo chown \$(whoami) /opt/newsletter-feature"
            exit 1
        fi
    fi
    
    # Create directory if it doesn't exist
    if [ ! -d "$DEPLOYMENT_DIR" ]; then
        if mkdir -p "$DEPLOYMENT_DIR"; then
            print_success "Created deployment directory: $DEPLOYMENT_DIR"
        else
            print_error "Failed to create deployment directory: $DEPLOYMENT_DIR"
            exit 1
        fi
    else
        print_success "Using existing deployment directory: $DEPLOYMENT_DIR"
    fi
    
    cd "$DEPLOYMENT_DIR"
}

# Function to create package.json
create_package_json() {
    print_status "Creating package.json..."
    
    cat > package.json << 'EOF'
{
  "name": "directus-newsletter-installer",
  "version": "1.0.0",
  "type": "module",
  "description": "Installer for Directus Newsletter Feature",
  "main": "newsletter-installer.js",
  "dependencies": {
    "@directus/sdk": "^17.0.0"
  },
  "engines": {
    "node": ">=16.0.0"
  },
  "scripts": {
    "install-newsletter": "node newsletter-installer.js"
  },
  "keywords": ["directus", "newsletter", "mjml", "email"],
  "author": "Your Agency",
  "license": "MIT"
}
EOF
    
    print_success "package.json created"
}

# Function to create installer script
create_installer_script() {
    print_status "Creating newsletter installer script..."
    
    cat > newsletter-installer.js << 'EOF'
#!/usr/bin/env node

/**
 * Directus Newsletter Feature Installer
 * Safely installs newsletter collections, relations, and flows to existing Directus instances
 */

import { createDirectus, rest, authentication, readCollections, createCollection, createField, createRelation, createFlow, createItems } from '@directus/sdk';
import readline from 'readline';

class NewsletterInstaller {
  constructor(directusUrl, email, password) {
    this.directus = createDirectus(directusUrl).with(rest()).with(authentication());
    this.email = email;
    this.password = password;
    this.existingCollections = new Set();
  }

  async initialize() {
    try {
      console.log('🔐 Authenticating with Directus...');
      await this.directus.login(this.email, this.password);
      console.log('✅ Authentication successful');

      const collections = await this.directus.request(readCollections());
      this.existingCollections = new Set(collections.map(c => c.collection));
      console.log(`📋 Found ${collections.length} existing collections`);
      
      return true;
    } catch (error) {
      console.error('❌ Authentication failed:', error.message);
      return false;
    }
  }

  async createCollections() {
    console.log('\n📦 Creating newsletter collections...');

    // Create collections in dependency order
    await this.createBlockTypesCollection();
    await this.createNewslettersCollection();
    await this.createNewsletterBlocksCollection();
    await this.createMailingListsCollection();
    await this.createNewsletterSendsCollection();
  }

  async createBlockTypesCollection() {
    if (this.existingCollections.has('block_types')) {
      console.log('⏭️  Skipping block_types - already exists');
      return;
    }

    console.log('📝 Creating block_types collection...');
    
    await this.directus.request(createCollection({
      collection: 'block_types',
      meta: {
        accountability: 'all',
        collection: 'block_types',
        group: null,
        hidden: false,
        icon: 'extension',
        item_duplication_fields: null,
        note: 'Available MJML block types for newsletters',
        singleton: false,
        translations: []
      },
      schema: { name: 'block_types' }
    }));

    // Add fields
    const fields = [
      {
        field: 'id',
        type: 'integer',
        meta: { hidden: true, interface: 'input', readonly: true },
        schema: { is_primary_key: true, has_auto_increment: true }
      },
      {
        field: 'name',
        type: 'string',
        meta: { interface: 'input', required: true, width: 'half' },
        schema: { is_nullable: false }
      },
      {
        field: 'slug',
        type: 'string',
        meta: { interface: 'input', required: true, width: 'half' },
        schema: { is_nullable: false }
      },
      {
        field: 'description',
        type: 'text',
        meta: { interface: 'input' }
      },
      {
        field: 'mjml_template',
        type: 'text',
        meta: {
          interface: 'input-code',
          options: { language: 'xml' },
          note: 'MJML template with Handlebars placeholders'
        },
        schema: { is_nullable: false }
      },
      {
        field: 'fields_schema',
        type: 'json',
        meta: {
          interface: 'input-code',
          options: { language: 'json' },
          note: 'JSON schema for block configuration fields'
        }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          options: {
            choices: [
              { text: 'Published', value: 'published' },
              { text: 'Draft', value: 'draft' },
              { text: 'Archived', value: 'archived' }
            ]
          },
          default_value: 'published'
        }
      }
    ];

    for (const field of fields) {
      await this.directus.request(createField('block_types', field));
    }

    console.log('✅ block_types collection created');
  }

  async createNewslettersCollection() {
    if (this.existingCollections.has('newsletters')) {
      console.log('⏭️  Skipping newsletters - already exists');
      return;
    }

    console.log('📝 Creating newsletters collection...');

    await this.directus.request(createCollection({
      collection: 'newsletters',
      meta: {
        accountability: 'all',
        collection: 'newsletters',
        group: null,
        hidden: false,
        icon: 'mail',
        item_duplication_fields: null,
        note: 'Email newsletters with MJML blocks',
        singleton: false,
        translations: []
      },
      schema: { name: 'newsletters' }
    }));

    const fields = [
      {
        field: 'id',
        type: 'integer',
        meta: { hidden: true, interface: 'input', readonly: true },
        schema: { is_primary_key: true, has_auto_increment: true }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          options: {
            choices: [
              { text: 'Draft', value: 'draft' },
              { text: 'Ready to Send', value: 'ready' },
              { text: 'Sent', value: 'sent' },
              { text: 'Scheduled', value: 'scheduled' }
            ]
          },
          default_value: 'draft',
          width: 'half'
        }
      },
      {
        field: 'title',
        type: 'string',
        meta: { interface: 'input', required: true, width: 'half' },
        schema: { is_nullable: false }
      },
      {
        field: 'subject_line',
        type: 'string',
        meta: { interface: 'input', required: true, note: 'Email subject line' },
        schema: { is_nullable: false }
      },
      {
        field: 'preview_text',
        type: 'string',
        meta: { interface: 'input', note: 'Preview text shown in email clients' }
      },
      {
        field: 'from_name',
        type: 'string',
        meta: { interface: 'input', default_value: 'Newsletter', width: 'half' }
      },
      {
        field: 'from_email',
        type: 'string',
        meta: { interface: 'input', width: 'half' }
      },
      {
        field: 'reply_to',
        type: 'string',
        meta: { interface: 'input', note: 'Reply-to email address' }
      },
      {
        field: 'scheduled_send',
        type: 'timestamp',
        meta: { interface: 'datetime', note: 'When to send if scheduled' }
      },
      {
        field: 'compiled_mjml',
        type: 'text',
        meta: {
          interface: 'input-code',
          options: { language: 'xml' },
          readonly: true,
          note: 'Auto-generated MJML from blocks'
        }
      },
      {
        field: 'compiled_html',
        type: 'text',
        meta: {
          interface: 'input-code',
          options: { language: 'htmlmixed' },
          readonly: true,
          note: 'Auto-generated HTML from MJML'
        }
      },
      {
        field: 'date_created',
        type: 'timestamp',
        meta: {
          interface: 'datetime',
          readonly: true,
          hidden: true,
          width: 'half',
          display: 'datetime',
          display_options: { relative: true }
        },
        schema: { default_value: 'CURRENT_TIMESTAMP' }
      },
      {
        field: 'date_updated',
        type: 'timestamp',
        meta: {
          interface: 'datetime',
          readonly: true,
          hidden: true,
          width: 'half',
          display: 'datetime',
          display_options: { relative: true }
        },
        schema: { default_value: 'CURRENT_TIMESTAMP' }
      },
      {
        field: 'user_created',
        type: 'uuid',
        meta: {
          interface: 'select-dropdown-m2o',
          readonly: true,
          hidden: true,
          width: 'half',
          display: 'user'
        }
      },
      {
        field: 'user_updated',
        type: 'uuid',
        meta: {
          interface: 'select-dropdown-m2o',
          readonly: true,
          hidden: true,
          width: 'half',
          display: 'user'
        }
      }
    ];

    for (const field of fields) {
      await this.directus.request(createField('newsletters', field));
    }

    console.log('✅ newsletters collection created');
  }

  async createNewsletterBlocksCollection() {
    if (this.existingCollections.has('newsletter_blocks')) {
      console.log('⏭️  Skipping newsletter_blocks - already exists');
      return;
    }

    console.log('📝 Creating newsletter_blocks collection...');

    await this.directus.request(createCollection({
      collection: 'newsletter_blocks',
      meta: {
        accountability: 'all',
        collection: 'newsletter_blocks',
        group: null,
        hidden: false,
        icon: 'view_module',
        item_duplication_fields: null,
        note: 'Individual MJML blocks for newsletters',
        singleton: false,
        translations: []
      },
      schema: { name: 'newsletter_blocks' }
    }));

    const fields = [
      {
        field: 'id',
        type: 'integer',
        meta: { hidden: true, interface: 'input', readonly: true },
        schema: { is_primary_key: true, has_auto_increment: true }
      },
      {
        field: 'newsletter_id',
        type: 'integer',
        meta: { interface: 'select-dropdown-m2o', hidden: true },
        schema: { is_nullable: false }
      },
      {
        field: 'block_type',
        type: 'integer',
        meta: { interface: 'select-dropdown-m2o', required: true, width: 'half' },
        schema: { is_nullable: false }
      },
      {
        field: 'sort',
        type: 'integer',
        meta: { interface: 'input', width: 'half' },
        schema: { default_value: 0 }
      },
      {
        field: 'content',
        type: 'json',
        meta: {
          interface: 'input-code',
          options: { language: 'json' },
          note: 'Block content data (varies by block type)'
        }
      },
      {
        field: 'mjml_output',
        type: 'text',
        meta: {
          interface: 'input-code',
          options: { language: 'xml' },
          readonly: true,
          note: 'Generated MJML for this block'
        }
      }
    ];

    for (const field of fields) {
      await this.directus.request(createField('newsletter_blocks', field));
    }

    console.log('✅ newsletter_blocks collection created');
  }

  async createMailingListsCollection() {
    const hasMailingList = this.existingCollections.has('mailing_list');
    const hasMailingLists = this.existingCollections.has('mailing_lists');

    if (hasMailingLists) {
      console.log('⏭️  Skipping mailing_lists - already exists');
      return;
    }

    console.log('📝 Creating mailing_lists collection...');

    await this.directus.request(createCollection({
      collection: 'mailing_lists',
      meta: {
        accountability: 'all',
        collection: 'mailing_lists',
        group: null,
        hidden: false,
        icon: 'group',
        item_duplication_fields: null,
        note: 'Mailing list groups for newsletters',
        singleton: false,
        translations: []
      },
      schema: { name: 'mailing_lists' }
    }));

    const fields = [
      {
        field: 'id',
        type: 'integer',
        meta: { hidden: true, interface: 'input', readonly: true },
        schema: { is_primary_key: true, has_auto_increment: true }
      },
      {
        field: 'name',
        type: 'string',
        meta: { interface: 'input', required: true },
        schema: { is_nullable: false }
      },
      {
        field: 'description',
        type: 'text',
        meta: { interface: 'input' }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          options: {
            choices: [
              { text: 'Active', value: 'active' },
              { text: 'Inactive', value: 'inactive' }
            ]
          },
          default_value: 'active'
        }
      }
    ];

    for (const field of fields) {
      await this.directus.request(createField('mailing_lists', field));
    }

    console.log('✅ mailing_lists collection created');
  }

  async createNewsletterSendsCollection() {
    if (this.existingCollections.has('newsletter_sends')) {
      console.log('⏭️  Skipping newsletter_sends - already exists');
      return;
    }

    console.log('📝 Creating newsletter_sends collection...');

    await this.directus.request(createCollection({
      collection: 'newsletter_sends',
      meta: {
        accountability: 'all',
        collection: 'newsletter_sends',
        group: null,
        hidden: false,
        icon: 'send',
        item_duplication_fields: null,
        note: 'Track newsletter send history and status',
        singleton: false,
        translations: []
      },
      schema: { name: 'newsletter_sends' }
    }));

    const fields = [
      {
        field: 'id',
        type: 'integer',
        meta: { hidden: true, interface: 'input', readonly: true },
        schema: { is_primary_key: true, has_auto_increment: true }
      },
      {
        field: 'newsletter_id',
        type: 'integer',
        meta: { interface: 'select-dropdown-m2o', required: true },
        schema: { is_nullable: false }
      },
      {
        field: 'mailing_list_id',
        type: 'integer',
        meta: { interface: 'select-dropdown-m2o', required: true },
        schema: { is_nullable: false }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          options: {
            choices: [
              { text: 'Pending', value: 'pending' },
              { text: 'Sending', value: 'sending' },
              { text: 'Sent', value: 'sent' },
              { text: 'Failed', value: 'failed' }
            ]
          },
          default_value: 'pending'
        }
      },
      {
        field: 'total_recipients',
        type: 'integer',
        meta: { interface: 'input', readonly: true }
      },
      {
        field: 'sent_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, default_value: 0 }
      },
      {
        field: 'failed_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, default_value: 0 }
      },
      {
        field: 'sendgrid_batch_id',
        type: 'string',
        meta: { interface: 'input', readonly: true, note: 'SendGrid batch ID for tracking' }
      },
      {
        field: 'error_log',
        type: 'text',
        meta: { interface: 'input-rich-text-md', readonly: true }
      },
      {
        field: 'sent_at',
        type: 'timestamp',
        meta: { interface: 'datetime', readonly: true }
      },
      {
        field: 'date_created',
        type: 'timestamp',
        meta: { interface: 'datetime', readonly: true, hidden: true },
        schema: { default_value: 'CURRENT_TIMESTAMP' }
      }
    ];

    for (const field of fields) {
      await this.directus.request(createField('newsletter_sends', field));
    }

    console.log('✅ newsletter_sends collection created');
  }

  async createRelations() {
    console.log('\n🔗 Creating relationships...');

    const relations = [
      {
        collection: 'newsletter_blocks',
        field: 'newsletter_id',
        related_collection: 'newsletters',
        meta: {
          many_collection: 'newsletter_blocks',
          many_field: 'newsletter_id',
          one_collection: 'newsletters',
          one_field: 'blocks',
          sort_field: 'sort',
          one_deselect_action: 'delete'
        }
      },
      {
        collection: 'newsletter_blocks',
        field: 'block_type',
        related_collection: 'block_types',
        meta: {
          many_collection: 'newsletter_blocks',
          many_field: 'block_type',
          one_collection: 'block_types',
          one_deselect_action: 'nullify'
        }
      },
      {
        collection: 'newsletter_sends',
        field: 'newsletter_id',
        related_collection: 'newsletters',
        meta: {
          many_collection: 'newsletter_sends',
          many_field: 'newsletter_id',
          one_collection: 'newsletters',
          one_deselect_action: 'nullify'
        }
      },
      {
        collection: 'newsletter_sends',
        field: 'mailing_list_id',
        related_collection: 'mailing_lists',
        meta: {
          many_collection: 'newsletter_sends',
          many_field: 'mailing_list_id',
          one_collection: 'mailing_lists',
          one_deselect_action: 'nullify'
        }
      }
    ];

    for (const relation of relations) {
      try {
        await this.directus.request(createRelation(relation));
        console.log(`✅ Created relation: ${relation.collection}.${relation.field} -> ${relation.related_collection}`);
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⏭️  Relation already exists: ${relation.collection}.${relation.field} -> ${relation.related_collection}`);
        } else {
          console.error(`❌ Failed to create relation: ${relation.collection}.${relation.field}`, error.message);
        }
      }
    }
  }

  async insertBlockTypes() {
    console.log('\n🧩 Installing starter block types...');

    const blockTypes = [
      {
        name: "Hero Section",
        slug: "hero",
        description: "Large header section with title, subtitle, and optional button",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    {{#if image_url}}
    <mj-image src="{{image_url}}" alt="{{image_alt}}" padding="0 0 20px 0" />
    {{/if}}
    <mj-text align="{{text_align}}" font-size="{{title_size}}" font-weight="bold" color="{{title_color}}" padding="0 0 10px 0">
      {{title}}
    </mj-text>
    {{#if subtitle}}
    <mj-text align="{{text_align}}" font-size="{{subtitle_size}}" color="{{subtitle_color}}" padding="0 0 20px 0">
      {{subtitle}}
    </mj-text>
    {{/if}}
    {{#if button_text}}
    <mj-button background-color="{{button_bg_color}}" color="{{button_text_color}}" href="{{button_url}}">
      {{button_text}}
    </mj-button>
    {{/if}}
  </mj-column>
</mj-section>`,
        fields_schema: {
          type: "object",
          properties: {
            title: { type: "string", title: "Title", default: "Welcome to Our Newsletter" },
            subtitle: { type: "string", title: "Subtitle" },
            image_url: { type: "string", title: "Image URL" },
            image_alt: { type: "string", title: "Image Alt Text" },
            button_text: { type: "string", title: "Button Text" },
            button_url: { type: "string", title: "Button URL" },
            background_color: { type: "string", title: "Background Color", default: "#ffffff" },
            title_color: { type: "string", title: "Title Color", default: "#000000" },
            subtitle_color: { type: "string", title: "Subtitle Color", default: "#666666" },
            button_bg_color: { type: "string", title: "Button Background", default: "#007bff" },
            button_text_color: { type: "string", title: "Button Text Color", default: "#ffffff" },
            title_size: { type: "string", title: "Title Font Size", default: "32px" },
            subtitle_size: { type: "string", title: "Subtitle Font Size", default: "18px" },
            text_align: { type: "string", title: "Text Alignment", enum: ["left", "center", "right"], default: "center" },
            padding: { type: "string", title: "Section Padding", default: "40px 0" }
          },
          required: ["title"]
        },
        status: "published"
      },
      {
        name: "Text Block",
        slug: "text",
        description: "Simple text content with formatting options",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-text align="{{text_align}}" font-size="{{font_size}}" color="{{text_color}}" line-height="{{line_height}}">
      {{content}}
    </mj-text>
  </mj-column>
</mj-section>`,
        fields_schema: {
          type: "object",
          properties: {
            content: { type: "string", title: "Content", format: "textarea" },
            background_color: { type: "string", title: "Background Color", default: "#ffffff" },
            text_color: { type: "string", title: "Text Color", default: "#000000" },
            font_size: { type: "string", title: "Font Size", default: "14px" },
            line_height: { type: "string", title: "Line Height", default: "1.6" },
            text_align: { type: "string", title: "Text Alignment", enum: ["left", "center", "right", "justify"], default: "left" },
            padding: { type: "string", title: "Section Padding", default: "20px 0" }
          },
          required: ["content"]
        },
        status: "published"
      },
      {
        name: "Image Block",
        slug: "image",
        description: "Single image with optional caption and link",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    {{#if href}}
    <mj-image src="{{src}}" alt="{{alt}}" href="{{href}}" width="{{width}}" align="{{align}}" />
    {{else}}
    <mj-image src="{{src}}" alt="{{alt}}" width="{{width}}" align="{{align}}" />
    {{/if}}
    {{#if caption}}
    <mj-text align="{{align}}" font-size="{{caption_size}}" color="{{caption_color}}" padding="10px 0 0 0">
      {{caption}}
    </mj-text>
    {{/if}}
  </mj-column>
</mj-section>`,
        fields_schema: {
          type: "object",
          properties: {
            src: { type: "string", title: "Image URL" },
            alt: { type: "string", title: "Alt Text" },
            href: { type: "string", title: "Link URL (optional)" },
            caption: { type: "string", title: "Caption (optional)" },
            width: { type: "string", title: "Image Width", default: "600px" },
            align: { type: "string", title: "Alignment", enum: ["left", "center", "right"], default: "center" },
            background_color: { type: "string", title: "Background Color", default: "#ffffff" },
            caption_color: { type: "string", title: "Caption Color", default: "#666666" },
            caption_size: { type: "string", title: "Caption Font Size", default: "12px" },
            padding: { type: "string", title: "Section Padding", default: "20px 0" }
          },
          required: ["src", "alt"]
        },
        status: "published"
      },
      {
        name: "Button",
        slug: "button",
        description: "Call-to-action button with customizable styling",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-button 
      background-color="{{button_bg_color}}" 
      color="{{button_text_color}}" 
      href="{{href}}" 
      font-size="{{font_size}}"
      font-weight="{{font_weight}}"
      border-radius="{{border_radius}}"
      padding="{{button_padding}}"
      align="{{align}}"
      width="{{width}}"
    >
      {{text}}
    </mj-button>
  </mj-column>
</mj-section>`,
        fields_schema: {
          type: "object",
          properties: {
            text: { type: "string", title: "Button Text" },
            href: { type: "string", title: "Button URL" },
            button_bg_color: { type: "string", title: "Button Background", default: "#007bff" },
            button_text_color: { type: "string", title: "Button Text Color", default: "#ffffff" },
            background_color: { type: "string", title: "Section Background", default: "#ffffff" },
            font_size: { type: "string", title: "Font Size", default: "16px" },
            font_weight: { type: "string", title: "Font Weight", default: "bold" },
            border_radius: { type: "string", title: "Border Radius", default: "4px" },
            button_padding: { type: "string", title: "Button Padding", default: "12px 24px" },
            align: { type: "string", title: "Alignment", enum: ["left", "center", "right"], default: "center" },
            width: { type: "string", title: "Button Width", default: "auto" },
            padding: { type: "string", title: "Section Padding", default: "20px 0" }
          },
          required: ["text", "href"]
        },
        status: "published"
      }
    ];

    for (const blockType of blockTypes) {
      try {
        await this.directus.request(createItems('block_types', blockType));
        console.log(`✅ Created block type: ${blockType.name}`);
      } catch (error) {
        console.log(`⚠️  Could not create block type ${blockType.name}:`, error.message);
      }
    }
  }

  async createFlow() {
    console.log('\n⚡ Creating newsletter send flow...');
    
    try {
      const flow = await this.directus.request(createFlow({
        name: 'Send Newsletter',
        icon: 'send',
        color: '#00D4AA',
        description: 'Compiles MJML blocks and sends newsletter to selected mailing lists',
        status: 'active',
        trigger: 'manual',
        accountability: 'all',
        options: {
          collections: ['newsletters'],
          location: 'item',
          requireConfirmation: true,
          confirmationDescription: 'This will send the newsletter to all selected mailing lists. Are you sure?'
        }
      }));

      console.log('✅ Newsletter flow created');
      console.log('⚠️  Note: You will need to manually configure the flow operations in Directus admin');

    } catch (error) {
      console.error('❌ Failed to create flow:', error.message);
    }
  }

  async run() {
    console.log('🚀 Starting Directus Newsletter Feature Installation\n');

    if (!(await this.initialize())) {
      return false;
    }

    const hasExisting = ['newsletters', 'newsletter_blocks', 'block_types', 'newsletter_sends']
      .some(c => this.existingCollections.has(c));
    
    if (hasExisting) {
      console.log('⚠️  Found existing newsletter collections. They will be skipped safely.');
    }

    try {
      await this.createCollections();
      await this.createRelations();
      await this.insertBlockTypes();
      await this.createFlow();

      console.log('\n🎉 Newsletter feature installation completed!');
      console.log('\nNext steps:');
      console.log('1. Copy the Nuxt server endpoints to your project');
      console.log('2. Configure environment variables');  
      console.log('3. Set up the flow operations in Directus admin');
      console.log('4. Test with a sample newsletter');
      
      return true;
    } catch (error) {
      console.error('\n❌ Installation failed:', error.message);
      return false;
    }
  }
}

// CLI Interface
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 3) {
    console.log('Usage: node newsletter-installer.js <directus-url> <email> <password>');
    console.log('Example: node newsletter-installer.js https://admin.example.com admin@example.com password123');
    process.exit(1);
  }

  const [directusUrl, email, password] = args;
  const installer = new NewsletterInstaller(directusUrl, email, password);
  
  const success = await installer.run();
  process.exit(success ? 0 : 1);
}

main().catch(console.error);
EOF
    
    chmod +x newsletter-installer.js
    print_success "Newsletter installer script created"
}

# Function to install Node.js dependencies
install_dependencies() {
    print_status "Installing Node.js dependencies..."
    
    if command_exists npm; then
        npm install
        print_success "Dependencies installed successfully"
    elif command_exists yarn; then
        yarn install
        print_success "Dependencies installed successfully (using yarn)"
    else
        print_error "Neither npm nor yarn found. Please install Node.js and npm first."
        exit 1
    fi
}

# Function to create Nuxt endpoints
create_nuxt_endpoints() {
    print_status "Creating Nuxt server endpoints..."
    
    mkdir -p server/api/newsletter
    
    # Create MJML compilation endpoint
    cat > server/api/newsletter/compile-mjml.post.ts << 'EOF'
import mjml2html from 'mjml'
import { createDirectus, rest, readItem, updateItem } from '@directus/sdk'
import Handlebars from 'handlebars'

export default defineEventHandler(async (event) => {
  try {
    const config = useRuntimeConfig()
    
    // Verify authorization
    const authHeader = getHeader(event, 'authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw createError({
        statusCode: 401,
        statusMessage: 'Unauthorized'
      })
    }

    const token = authHeader.split(' ')[1]
    if (token !== config.directusWebhookSecret) {
      throw createError({
        statusCode: 401,
        statusMessage: 'Invalid token'
      })
    }

    const body = await readBody(event)
    const { newsletter_id } = body

    if (!newsletter_id) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Newsletter ID is required'
      })
    }

    // Initialize Directus client
    const directus = createDirectus(config.public.directusUrl as string).with(rest())

    // Fetch newsletter with blocks and block types
    const newsletter = await directus.request(
      readItem('newsletters', newsletter_id, {
        fields: [
          '*',
          'blocks.id',
          'blocks.sort', 
          'blocks.content',
          'blocks.block_type.name',
          'blocks.block_type.slug',
          'blocks.block_type.mjml_template'
        ]
      })
    )

    if (!newsletter) {
      throw createError({
        statusCode: 404,
        statusMessage: 'Newsletter not found'
      })
    }

    // Sort blocks by sort order
    const sortedBlocks = newsletter.blocks?.sort((a: any, b: any) => a.sort - b.sort) || []

    // Compile each block
    let compiledBlocks = ''
    
    for (const block of sortedBlocks) {
      if (!block.block_type?.mjml_template) {
        console.warn(`Block ${block.id} has no MJML template`)
        continue
      }

      try {
        // Compile handlebars template with block content
        const template = Handlebars.compile(block.block_type.mjml_template)
        const blockMjml = template(block.content || {})
        
        // Store compiled MJML for this block
        await directus.request(
          updateItem('newsletter_blocks', block.id, {
            mjml_output: blockMjml
          })
        )

        compiledBlocks += blockMjml + '\n'
      } catch (error) {
        console.error(`Error compiling block ${block.id}:`, error)
        const errorMessage = error instanceof Error ? error.message : String(error)
        throw createError({
          statusCode: 500,
          statusMessage: `Error compiling block ${block.id}: ${errorMessage}`
        })
      }
    }

    // Header and footer partials
    const headerPartial = `
    <mj-section background-color="#ffffff" padding="20px 0">
      <mj-column>
        <mj-image src="${config.public.siteUrl || config.public.directusUrl}/assets/logo.png" alt="Newsletter" width="200px" align="center" />
      </mj-column>
    </mj-section>`

    const footerPartial = `
    <mj-section background-color="#f8f9fa" padding="40px 20px">
      <mj-column>
        <mj-text align="center" font-size="12px" color="#666666">
          <p>You received this email because you subscribed to our newsletter.</p>
          <p>
            <a href="{{unsubscribe_url}}" style="color: #666666; text-decoration: underline;">Unsubscribe</a> |
            <a href="{{preferences_url}}" style="color: #666666; text-decoration: underline;">Update Preferences</a>
          </p>
          <p>© ${new Date().getFullYear()} Newsletter. All rights reserved.</p>
        </mj-text>
      </mj-column>
    </mj-section>`

    // Build complete MJML
    const completeMjml = `
    <mjml>
      <mj-head>
        <mj-title>${newsletter.subject_line}</mj-title>
        <mj-preview>${newsletter.preview_text || ''}</mj-preview>
        <mj-attributes>
          <mj-all font-family="Arial, sans-serif" />
          <mj-text font-size="14px" color="#333333" line-height="1.6" />
          <mj-section background-color="#ffffff" />
        </mj-attributes>
      </mj-head>
      <mj-body>
        ${headerPartial}
        ${compiledBlocks}
        ${footerPartial}
      </mj-body>
    </mjml>`

    // Compile MJML to HTML
    const mjmlResult = mjml2html(completeMjml, {
      validationLevel: 'soft'
    })

    if (mjmlResult.errors.length > 0) {
      console.warn('MJML compilation warnings:', mjmlResult.errors)
    }

    // Update newsletter with compiled MJML and HTML
    await directus.request(
      updateItem('newsletters', newsletter_id, {
        compiled_mjml: completeMjml,
        compiled_html: mjmlResult.html
      })
    )

    return {
      success: true,
      message: 'MJML compiled successfully',
      warnings: mjmlResult.errors.length > 0 ? mjmlResult.errors : null
    }

  } catch (error: any) {
    console.error('MJML compilation error:', error)
    
    const errorMessage = error instanceof Error ? error.message : String(error)
    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || errorMessage
    })
  }
})
EOF

    # Create newsletter send endpoint
    cat > server/api/newsletter/send.post.ts << 'EOF'
import sgMail from '@sendgrid/mail'
import { createDirectus, rest, readItem, updateItem } from '@directus/sdk'

export default defineEventHandler(async (event) => {
  try {
    const config = useRuntimeConfig()
    
    // Initialize SendGrid
    sgMail.setApiKey(config.sendgridApiKey)

    // Verify authorization
    const authHeader = getHeader(event, 'authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw createError({
        statusCode: 401,
        statusMessage: 'Unauthorized'
      })
    }

    const token = authHeader.split(' ')[1]
    if (token !== config.directusWebhookSecret) {
      throw createError({
        statusCode: 401,
        statusMessage: 'Invalid token'
      })
    }

    const body = await readBody(event)
    const { newsletter_id, send_record_id } = body

    if (!newsletter_id || !send_record_id) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Newsletter ID and Send Record ID are required'
      })
    }

    // Initialize Directus client
    const directus = createDirectus(config.public.directusUrl as string).with(rest())

    // Update send record to "sending"
    await directus.request(
      updateItem('newsletter_sends', send_record_id, {
        status: 'sending'
      })
    )

    // Fetch newsletter
    const newsletter = await directus.request(
      readItem('newsletters', newsletter_id, {
        fields: ['*']
      })
    )

    if (!newsletter || !newsletter.compiled_html) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Newsletter not found or HTML not compiled'
      })
    }

    // Fetch send record to get specific mailing list
    const sendRecord = await directus.request(
      readItem('newsletter_sends', send_record_id, {
        fields: [
          '*',
          'mailing_list_id.id',
          'mailing_list_id.name',
          'mailing_list_id.subscribers.mailing_list_id.*'
        ]
      })
    )

    const mailingList = sendRecord.mailing_list_id
    const subscribers = mailingList?.subscribers || []

    if (subscribers.length === 0) {
      await directus.request(
        updateItem('newsletter_sends', send_record_id, {
          status: 'sent',
          sent_count: 0,
          sent_at: new Date().toISOString()
        })
      )

      return {
        success: true,
        message: 'No subscribers in mailing list',
        sent_count: 0
      }
    }

    // Helper function to generate unsubscribe tokens
    function generateUnsubscribeToken(email: string): string {
      const crypto = require('node:crypto')
      const data = `${email}:${config.directusWebhookSecret}`
      return crypto.createHash('sha256').update(data).digest('hex').substring(0, 16)
    }

    // Prepare email data
    const fromEmail = newsletter.from_email || 'newsletter@example.com'
    const fromName = newsletter.from_name || 'Newsletter'
    const replyTo = newsletter.reply_to || fromEmail

    // Generate unique batch ID for SendGrid
    const batchId = `newsletter_${newsletter_id}_${Date.now()}`

    // Create personalizations for each subscriber
    const personalizations = subscribers.map((subscriber: any) => {
      const unsubscribeUrl = `${config.public.siteUrl}/unsubscribe?email=${encodeURIComponent(subscriber.email)}&token=${generateUnsubscribeToken(subscriber.email)}`
      const preferencesUrl = `${config.public.siteUrl}/email-preferences?email=${encodeURIComponent(subscriber.email)}&token=${generateUnsubscribeToken(subscriber.email)}`

      // Replace placeholders in HTML
      let personalizedHtml = newsletter.compiled_html
        .replace(/{{unsubscribe_url}}/g, unsubscribeUrl)
        .replace(/{{preferences_url}}/g, preferencesUrl)
        .replace(/{{subscriber_name}}/g, subscriber.name || 'Subscriber')
        .replace(/{{subscriber_email}}/g, subscriber.email)

      return {
        to: [
          {
            email: subscriber.email,
            name: subscriber.name || ''
          }
        ]
      }
    })

    // Prepare the email message
    const msg = {
      from: {
        email: fromEmail,
        name: fromName
      },
      reply_to: {
        email: replyTo,
        name: fromName
      },
      subject: newsletter.subject_line,
      html: newsletter.compiled_html,
      personalizations: personalizations,
      batch_id: batchId,
      tracking_settings: {
        click_tracking: {
          enable: true,
          enable_text: true
        },
        open_tracking: {
          enable: true
        }
      }
    }

    let sentCount = 0
    let failedCount = 0
    const errors: string[] = []

    try {
      // Send emails in batches to avoid rate limits
      const batchSize = 100
      const batches = []
      
      for (let i = 0; i < personalizations.length; i += batchSize) {
        batches.push(personalizations.slice(i, i + batchSize))
      }

      for (const batch of batches) {
        try {
          const batchMsg = {
            ...msg,
            personalizations: batch
          }

          await sgMail.send(batchMsg)
          sentCount += batch.length
          
          // Add small delay between batches
          if (batches.length > 1) {
            await new Promise(resolve => setTimeout(resolve, 1000))
          }
        } catch (batchError: any) {
          failedCount += batch.length
          const errorMessage = batchError instanceof Error ? batchError.message : String(batchError)
          errors.push(`Batch error: ${errorMessage}`)
          console.error('SendGrid batch error:', batchError)
        }
      }

      // Update send record with results
      await directus.request(
        updateItem('newsletter_sends', send_record_id, {
          status: failedCount === 0 ? 'sent' : (sentCount > 0 ? 'sent' : 'failed'),
          sent_count: sentCount,
          failed_count: failedCount,
          sendgrid_batch_id: batchId,
          sent_at: new Date().toISOString(),
          error_log: errors.length > 0 ? errors.join('\n') : null
        })
      )

      return {
        success: true,
        message: `Newsletter sent to ${sentCount} recipients`,
        sent_count: sentCount,
        failed_count: failedCount,
        batch_id: batchId
      }

    } catch (error: any) {
      console.error('SendGrid error:', error)
      
      const errorMessage = error instanceof Error ? error.message : String(error)
      // Update send record as failed
      await directus.request(
        updateItem('newsletter_sends', send_record_id, {
          status: 'failed',
          sent_count: sentCount,
          failed_count: subscribers.length - sentCount,
          error_log: errorMessage,
          sent_at: new Date().toISOString()
        })
      )

      throw error
    }

  } catch (error: any) {
    console.error('Newsletter send error:', error)
    
    const errorMessage = error instanceof Error ? error.message : String(error)
    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || errorMessage
    })
  }
})
EOF

    print_success "Nuxt endpoints created in server/api/newsletter/"
}

# Function to create example environment file
create_env_example() {
    print_status "Creating environment configuration example..."
    
    cat > .env.example << 'EOF'
# Directus Configuration
DIRECTUS_URL=https://your-directus-instance.com
DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret

# SendGrid Configuration
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_UNSUBSCRIBE_GROUP_ID=12345

# Site Configuration
NUXT_SITE_URL=https://your-site.com
EOF

    print_success "Environment configuration example created (.env.example)"
}

# Function to create installation summary
create_summary() {
    print_status "Creating installation summary..."
    
    cat > INSTALLATION_SUMMARY.md << 'EOF'
# Newsletter Feature Installation Summary

## What Was Installed

✅ Node.js installer script with dependencies
✅ Nuxt.js server endpoint templates  
✅ Environment configuration example
✅ Installation documentation

## Quick Install

```bash
# Install to Directus instance
node newsletter-installer.js https://your-directus-url.com admin@example.com your-password
```

## Next Steps

### 1. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
# Edit .env with your actual values
```

### 2. Copy Nuxt Endpoints

Copy the server endpoints to your Nuxt project:

```bash
# Copy to your existing Nuxt project
cp -r server/ /path/to/your/nuxt/project/server/
```

### 3. Install Node Dependencies in Your Nuxt Project

```bash
cd /path/to/your/nuxt/project
npm install mjml @sendgrid/mail handlebars @directus/sdk
npm install -D @types/mjml
```

### 4. Update Nuxt Config

Add to your `nuxt.config.ts`:

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

### 5. Complete Setup in Directus Admin

1. Log into Directus Admin
2. Configure the newsletter send flow operations
3. Test with a sample newsletter

## Support

For detailed setup instructions, see the complete documentation.
EOF

    print_success "Installation summary created (INSTALLATION_SUMMARY.md)"
}

# Function to run the installer
run_installer() {
    local directus_url=$1
    local email=$2
    local password=$3
    
    print_status "Running newsletter feature installer..."
    
    if validate_url "$directus_url"; then
        if test_directus_connection "$directus_url"; then
            node newsletter-installer.js "$directus_url" "$email" "$password"
            if [ $? -eq 0 ]; then
                print_success "Newsletter feature installed successfully!"
                echo ""
                print_status "Next steps:"
                echo "1. Copy server/api/newsletter/ to your Nuxt project"
                echo "2. Install dependencies: npm install mjml @sendgrid/mail handlebars"
                echo "3. Configure environment variables"
                echo "4. Set up flow operations in Directus admin"
            else
                print_error "Installation failed. Check the output above for details."
                return 1
            fi
        else
            print_error "Cannot connect to Directus. Please check the URL and try again."
            return 1
        fi
    else
        print_error "Invalid Directus URL format. Please use http:// or https://"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Directus Newsletter Feature - Deployment Script v${VERSION}"
    echo ""
    echo "Usage:"
    echo "  $0 setup                           # Download and setup installation files"
    echo "  $0 install <url> <email> <pass>    # Install feature to Directus instance"
    echo "  $0 full <url> <email> <pass>       # Setup and install in one command"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 install https://admin.example.com admin@example.com mypassword"
    echo "  $0 full https://admin.example.com admin@example.com mypassword"
    echo ""
}

# Main execution
main() {
    echo "======================================================"
    echo "   Directus Newsletter Feature - Deployment Script"
    echo "                    Version ${VERSION}"
    echo "======================================================"
    echo ""

    # Check if Node.js is installed
    if ! command_exists node; then
        print_error "Node.js is not installed. Please install Node.js 16+ first."
        echo "Visit: https://nodejs.org/"
        exit 1
    fi

    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_error "Node.js 16+ is required. Current version: $(node --version)"
        exit 1
    fi

    # Show permission info if not root
    if [ "$EUID" -ne 0 ]; then
        print_status "Running as non-root user. If you encounter permission errors:"
        echo "  • Run with sudo: curl ... | sudo bash -s ..."
        echo "  • Or set custom directory: NEWSLETTER_DEPLOY_DIR=~/newsletter curl ... | bash -s ..."
        echo ""
    fi

    # Parse command line arguments
    case "$1" in
        "setup")
            print_status "Setting up newsletter feature installation..."
            setup_deployment_dir
            create_package_json
            create_installer_script
            install_dependencies
            create_nuxt_endpoints
            create_env_example
            create_summary
            print_success "Setup completed! Check INSTALLATION_SUMMARY.md for next steps."
            ;;
        "install")
            if [ $# -ne 4 ]; then
                print_error "Install command requires 3 arguments: <directus-url> <email> <password>"
                show_usage
                exit 1
            fi
            cd "$DEPLOYMENT_DIR" 2>/dev/null || {
                print_error "Installation files not found. Run '$0 setup' first."
                exit 1
            }
            run_installer "$2" "$3" "$4"
            ;;
        "full")
            if [ $# -ne 4 ]; then
                print_error "Full command requires 3 arguments: <directus-url> <email> <password>"
                show_usage
                exit 1
            fi
            print_status "Running full setup and installation..."
            setup_deployment_dir
            create_package_json
            create_installer_script
            install_dependencies
            create_nuxt_endpoints
            create_env_example
            create_summary
            print_success "Setup completed!"
            echo ""
            run_installer "$2" "$3" "$4"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"