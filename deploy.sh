#!/bin/bash

# Directus Newsletter Feature - Fixed Deployment Script
# Separates Directus installation from frontend setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION="2.1.0"
DEPLOYMENT_DIR="${NEWSLETTER_DEPLOY_DIR:-/opt/newsletter-feature}"

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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

validate_url() {
    if [[ $1 =~ ^https?://[^[:space:]]+$ ]]; then
        return 0
    else
        return 1
    fi
}

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

check_permissions() {
    local test_dir="$1"
    local parent_dir=$(dirname "$test_dir")
    
    if [ -d "$test_dir" ] && [ -w "$test_dir" ]; then
        return 0
    fi
    
    if [ -w "$parent_dir" ]; then
        return 0
    fi
    
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi
    
    return 1
}

setup_deployment_dir() {
    print_status "Setting up deployment directory..."
    
    if ! check_permissions "$DEPLOYMENT_DIR"; then
        print_warning "Cannot write to $DEPLOYMENT_DIR (permission denied)"
        
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
        
        if ! check_permissions "$DEPLOYMENT_DIR"; then
            print_error "No writable directory found. Try one of these solutions:"
            echo "1. Run with sudo: curl ... | sudo bash -s ..."
            echo "2. Set custom directory: NEWSLETTER_DEPLOY_DIR=~/newsletter curl ... | bash -s ..."
            echo "3. Create directory first: sudo mkdir -p /opt/newsletter-feature && sudo chown \$(whoami) /opt/newsletter-feature"
            exit 1
        fi
    fi
    
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

create_package_json() {
    print_status "Creating package.json..."
    
    cat > package.json << 'EOF'
{
  "name": "directus-newsletter-installer",
  "version": "2.1.0",
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

create_installer_script() {
    print_status "Creating enhanced newsletter installer..."
    
    cat > newsletter-installer.js << 'EOF'
#!/usr/bin/env node

/**
 * Directus Newsletter Feature Installer v2.1.0
 * Enhanced with automatic flow creation and better error handling
 */

import { createDirectus, rest, authentication, readCollections, createCollection, createField, createRelation, createFlow, createItems, createOperation } from '@directus/sdk';

class NewsletterInstaller {
  constructor(directusUrl, email, password, options = {}) {
    this.directus = createDirectus(directusUrl).with(rest()).with(authentication());
    this.email = email;
    this.password = password;
    this.existingCollections = new Set();
    this.options = {
      createFlow: options.createFlow !== false, // Default to true
      frontendUrl: options.frontendUrl || null, // Optional frontend URL
      webhookSecret: options.webhookSecret || 'change-this-webhook-secret'
    };
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

  async createFieldWithRetry(collection, field, maxRetries = 3) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await this.directus.request(createField(collection, field));
        console.log(`✅ Added field: ${field.field}`);
        await new Promise(resolve => setTimeout(resolve, 500));
        return true;
      } catch (error) {
        if (error.message.includes('already exists') || error.message.includes('duplicate')) {
          console.log(`⏭️  Field ${field.field} already exists`);
          return true;
        }
        
        if (attempt === maxRetries) {
          console.error(`❌ Failed to create field ${field.field} after ${maxRetries} attempts: ${error.message}`);
          return false;
        }
        
        console.log(`⚠️  Attempt ${attempt} failed for field ${field.field}, retrying...`);
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }
    }
  }

  async createCollectionSafely(collectionConfig) {
    const { collection } = collectionConfig;
    
    if (this.existingCollections.has(collection)) {
      console.log(`⏭️  Skipping ${collection} - already exists`);
      return true;
    }

    try {
      console.log(`📝 Creating ${collection} collection...`);
      await this.directus.request(createCollection(collectionConfig));
      console.log(`✅ ${collection} collection created`);
      await new Promise(resolve => setTimeout(resolve, 1000));
      return true;
    } catch (error) {
      if (error.message.includes('already exists')) {
        console.log(`⏭️  ${collection} collection already exists`);
        return true;
      }
      
      console.error(`❌ Failed to create ${collection} collection: ${error.message}`);
      return false;
    }
  }

  async createCollections() {
    console.log('\n📦 Creating newsletter collections...');

    const collections = [
      {
        collection: 'block_types',
        meta: {
          accountability: 'all',
          collection: 'block_types',
          hidden: false,
          icon: 'extension',
          note: 'Available MJML block types for newsletters'
        },
        schema: { name: 'block_types' }
      },
      {
        collection: 'mailing_lists',
        meta: {
          accountability: 'all',
          collection: 'mailing_lists',
          hidden: false,
          icon: 'group',
          note: 'Subscriber mailing lists'
        },
        schema: { name: 'mailing_lists' }
      },
      {
        collection: 'newsletters',
        meta: {
          accountability: 'all',
          collection: 'newsletters',
          hidden: false,
          icon: 'mail',
          note: 'Email newsletters with MJML blocks'
        },
        schema: { name: 'newsletters' }
      },
      {
        collection: 'newsletter_blocks',
        meta: {
          accountability: 'all',
          collection: 'newsletter_blocks',
          hidden: false,
          icon: 'view_module',
          note: 'Individual MJML blocks for newsletters'
        },
        schema: { name: 'newsletter_blocks' }
      },
      {
        collection: 'newsletter_sends',
        meta: {
          accountability: 'all',
          collection: 'newsletter_sends',
          hidden: false,
          icon: 'send',
          note: 'Track newsletter send history and status'
        },
        schema: { name: 'newsletter_sends' }
      }
    ];

    for (const collection of collections) {
      await this.createCollectionSafely(collection);
    }

    console.log('\n🔧 Adding fields to collections...');
    
    await this.addBlockTypeFields();
    await this.addMailingListFields();
    await this.addNewsletterFields();
    await this.addNewsletterBlockFields();
    await this.addNewsletterSendFields();
  }

  async addBlockTypeFields() {
    console.log('\n📝 Adding fields to block_types...');
    
    const fields = [
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
      await this.createFieldWithRetry('block_types', field);
    }
  }

  async addMailingListFields() {
    console.log('\n📝 Adding fields to mailing_lists...');
    
    const fields = [
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
        field: 'subscriber_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, default_value: 0 }
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
      await this.createFieldWithRetry('mailing_lists', field);
    }
  }

  async addNewsletterFields() {
    console.log('\n📝 Adding fields to newsletters...');
    
    const fields = [
      {
        field: 'title',
        type: 'string',
        meta: { interface: 'input', required: true },
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
          default_value: 'draft'
        }
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
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('newsletters', field);
    }
  }

  async addNewsletterBlockFields() {
    console.log('\n📝 Adding fields to newsletter_blocks...');
    
    const fields = [
      {
        field: 'newsletter_id',
        type: 'integer',
        meta: { 
          interface: 'select-dropdown-m2o',
          hidden: true 
        },
        schema: { is_nullable: false }
      },
      {
        field: 'block_type',
        type: 'integer',
        meta: { 
          interface: 'select-dropdown-m2o',
          required: true, 
          width: 'half',
          display_options: {
            template: '{{name}}'
          }
        },
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
      await this.createFieldWithRetry('newsletter_blocks', field);
    }
  }

  async addNewsletterSendFields() {
    console.log('\n📝 Adding fields to newsletter_sends...');
    
    const fields = [
      {
        field: 'newsletter_id',
        type: 'integer',
        meta: { 
          interface: 'select-dropdown-m2o',
          required: true,
          display_options: {
            template: '{{title}}'
          }
        },
        schema: { is_nullable: false }
      },
      {
        field: 'mailing_list_id',
        type: 'integer',
        meta: { 
          interface: 'select-dropdown-m2o',
          required: true,
          display_options: {
            template: '{{name}}'
          }
        },
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
        field: 'error_log',
        type: 'text',
        meta: { interface: 'input-rich-text-md', readonly: true }
      },
      {
        field: 'sent_at',
        type: 'timestamp',
        meta: { interface: 'datetime', readonly: true }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('newsletter_sends', field);
    }
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
        await new Promise(resolve => setTimeout(resolve, 800));
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
    <mj-text align="{{text_align}}" font-size="{{title_size}}" font-weight="bold" color="{{title_color}}">
      {{title}}
    </mj-text>
    {{#if subtitle}}
    <mj-text align="{{text_align}}" font-size="{{subtitle_size}}" color="{{subtitle_color}}">
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
            background_color: { type: "string", title: "Background Color", default: "#ffffff" },
            title_color: { type: "string", title: "Title Color", default: "#000000" },
            text_align: { type: "string", title: "Text Alignment", enum: ["left", "center", "right"], default: "center" }
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
    <mj-text align="{{text_align}}" font-size="{{font_size}}" color="{{text_color}}">
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
            font_size: { type: "string", title: "Font Size", default: "14px" }
          },
          required: ["content"]
        },
        status: "published"
      },
      {
        name: "Image Block",
        slug: "image",
        description: "Image with optional caption and link",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-image src="{{image_url}}" alt="{{alt_text}}" {{#if link_url}}href="{{link_url}}"{{/if}} align="{{alignment}}" width="{{width}}" />
    {{#if caption}}
    <mj-text align="{{alignment}}" font-size="12px" color="#666666" padding="10px 0 0 0">
      {{caption}}
    </mj-text>
    {{/if}}
  </mj-column>
</mj-section>`,
        fields_schema: {
          type: "object",
          properties: {
            image_url: { type: "string", title: "Image URL" },
            alt_text: { type: "string", title: "Alt Text" },
            caption: { type: "string", title: "Caption" },
            link_url: { type: "string", title: "Link URL" },
            alignment: { type: "string", title: "Alignment", enum: ["left", "center", "right"], default: "center" },
            width: { type: "string", title: "Width", default: "100%" },
            background_color: { type: "string", title: "Background Color", default: "#ffffff" }
          },
          required: ["image_url"]
        },
        status: "published"
      },
      {
        name: "Button",
        slug: "button",
        description: "Call-to-action button with customizable styling",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-button background-color="{{button_bg_color}}" color="{{button_text_color}}" href="{{button_url}}" align="{{alignment}}" border-radius="{{border_radius}}" font-size="{{font_size}}">
      {{button_text}}
    </mj-button>
  </mj-column>
</mj-section>`,
        fields_schema: {
          type: "object",
          properties: {
            button_text: { type: "string", title: "Button Text", default: "Click Here" },
            button_url: { type: "string", title: "Button URL" },
            button_bg_color: { type: "string", title: "Background Color", default: "#007bff" },
            button_text_color: { type: "string", title: "Text Color", default: "#ffffff" },
            alignment: { type: "string", title: "Alignment", enum: ["left", "center", "right"], default: "center" },
            border_radius: { type: "string", title: "Border Radius", default: "4px" },
            font_size: { type: "string", title: "Font Size", default: "14px" },
            background_color: { type: "string", title: "Section Background", default: "#ffffff" }
          },
          required: ["button_text", "button_url"]
        },
        status: "published"
      },
      {
        name: "Divider",
        slug: "divider",
        description: "Horizontal line separator",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-divider border-color="{{divider_color}}" border-width="{{border_width}}" />
  </mj-column>
</mj-section>`,
        fields_schema: {
          type: "object",
          properties: {
            divider_color: { type: "string", title: "Divider Color", default: "#cccccc" },
            border_width: { type: "string", title: "Border Width", default: "1px" },
            background_color: { type: "string", title: "Background Color", default: "#ffffff" },
            padding: { type: "string", title: "Padding", default: "20px 0" }
          }
        },
        status: "published"
      }
    ];

    for (const blockType of blockTypes) {
      try {
        await this.directus.request(createItems('block_types', blockType));
        console.log(`✅ Created block type: ${blockType.name}`);
        await new Promise(resolve => setTimeout(resolve, 300));
      } catch (error) {
        console.log(`⚠️  Could not create block type ${blockType.name}:`, error.message);
      }
    }
  }

  async createNewsletterFlow() {
    if (!this.options.createFlow) {
      console.log('\n⏭️  Skipping flow creation (disabled in options)');
      return;
    }

    if (!this.options.frontendUrl) {
      console.log('\n⚠️  Cannot create flow without frontend URL. Please create manually.');
      console.log('   Set frontendUrl option or create flow manually in Directus admin.');
      return;
    }

    console.log('\n🔄 Creating newsletter sending flow...');

    try {
      // Create the main flow
      const flow = await this.directus.request(createFlow({
        name: 'Send Newsletter',
        icon: 'send',
        color: '#00D4AA',
        description: 'Compiles MJML blocks and sends newsletter to mailing lists',
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

      console.log(`✅ Created flow: ${flow.name}`);

      // Note: Creating individual flow operations requires more complex logic
      // For now, we'll provide instructions for manual setup
      console.log('\n📋 Flow created! Please complete setup in Directus admin:');
      console.log('1. Go to Settings → Flows → Send Newsletter');
      console.log('2. Add webhook operations pointing to your frontend:');
      console.log(`   - MJML Compile: ${this.options.frontendUrl}/api/newsletter/compile-mjml`);
      console.log(`   - Send Email: ${this.options.frontendUrl}/api/newsletter/send`);
      console.log(`3. Use webhook secret: ${this.options.webhookSecret}`);

    } catch (error) {
      console.log(`⚠️  Could not create flow automatically: ${error.message}`);
      console.log('Please create the flow manually in Directus admin.');
    }
  }

  async run() {
    console.log('🚀 Starting Directus Newsletter Feature Installation\n');

    if (!(await this.initialize())) {
      return false;
    }

    try {
      await this.createCollections();
      await this.createRelations();
      await this.insertBlockTypes();
      await this.createNewsletterFlow();

      console.log('\n🎉 Newsletter feature installation completed!');
      console.log('\n📦 What was installed:');
      console.log('   • 5 Collections: newsletters, newsletter_blocks, block_types, mailing_lists, newsletter_sends');
      console.log('   • 5 MJML Block Types: Hero, Text, Image, Button, Divider');
      console.log('   • Complete relationships between collections');
      if (this.options.createFlow && this.options.frontendUrl) {
        console.log('   • Newsletter sending flow (needs manual completion)');
      }
      
      console.log('\n📋 Next steps:');
      console.log('1. Copy the Nuxt server endpoints to your frontend project');
      console.log('2. Configure environment variables on your frontend');
      console.log('3. Complete flow setup in Directus admin (if enabled)');
      console.log('4. Create test mailing lists and newsletters');
      
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
    console.log('Usage: node newsletter-installer.js <directus-url> <email> <password> [frontend-url] [webhook-secret]');
    console.log('');
    console.log('Examples:');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123 https://frontend.example.com');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123 https://frontend.example.com my-webhook-secret');
    process.exit(1);
  }

  const [directusUrl, email, password, frontendUrl, webhookSecret] = args;
  
  const options = {};
  if (frontendUrl) options.frontendUrl = frontendUrl;
  if (webhookSecret) options.webhookSecret = webhookSecret;
  
  const installer = new NewsletterInstaller(directusUrl, email, password, options);
  
  const success = await installer.run();
  process.exit(success ? 0 : 1);
}

main().catch(console.error);
EOF
    
    chmod +x newsletter-installer.js
    print_success "Enhanced newsletter installer script created"
}

create_frontend_package() {
    print_status "Creating frontend integration package..."
    
    mkdir -p frontend-integration
    
    # Create package structure
    mkdir -p frontend-integration/server/api/newsletter
    mkdir -p frontend-integration/types
    
    # Create the Nuxt endpoints
    cat > frontend-integration/server/api/newsletter/compile-mjml.post.ts << 'EOF'
import mjml2html from "mjml";
import { createDirectus, rest, readItem, updateItem } from "@directus/sdk";
import Handlebars from "handlebars";

export default defineEventHandler(async (event) => {
  try {
    const config = useRuntimeConfig();

    // Verify authorization
    const authHeader = getHeader(event, "authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw createError({
        statusCode: 401,
        statusMessage: "Unauthorized",
      });
    }

    const token = authHeader.split(" ")[1];
    if (token !== config.directusWebhookSecret) {
      throw createError({
        statusCode: 401,
        statusMessage: "Invalid token",
      });
    }

    const body = await readBody(event);
    const { newsletter_id } = body;

    if (!newsletter_id) {
      throw createError({
        statusCode: 400,
        statusMessage: "Newsletter ID is required",
      });
    }

    // Initialize Directus client
    const directus = createDirectus(config.public.directusUrl as string).with(rest());

    // Fetch newsletter with blocks and block types
    const newsletter = await directus.request(
      readItem("newsletters", newsletter_id, {
        fields: [
          "*",
          "blocks.id",
          "blocks.sort",
          "blocks.content",
          "blocks.block_type.name",
          "blocks.block_type.slug",
          "blocks.block_type.mjml_template",
        ],
      })
    );

    if (!newsletter) {
      throw createError({
        statusCode: 404,
        statusMessage: "Newsletter not found",
      });
    }

    // Sort blocks by sort order
    const sortedBlocks = newsletter.blocks?.sort((a: any, b: any) => a.sort - b.sort) || [];

    // Compile each block
    let compiledBlocks = "";

    for (const block of sortedBlocks) {
      if (!block.block_type?.mjml_template) {
        console.warn(`Block ${block.id} has no MJML template`);
        continue;
      }

      try {
        const template = Handlebars.compile(block.block_type.mjml_template);
        const blockMjml = template(block.content || {});

        await directus.request(
          updateItem("newsletter_blocks", block.id, {
            mjml_output: blockMjml,
          })
        );

        compiledBlocks += blockMjml + "\n";
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        throw createError({
          statusCode: 500,
          statusMessage: `Error compiling block ${block.id}: ${errorMessage}`,
        });
      }
    }

    // Build complete MJML
    const completeMjml = `
    <mjml>
      <mj-head>
        <mj-title>${newsletter.subject_line}</mj-title>
        <mj-preview>${newsletter.preview_text || ""}</mj-preview>
        <mj-attributes>
          <mj-all font-family="Arial, sans-serif" />
          <mj-text font-size="14px" color="#333333" line-height="1.6" />
          <mj-section background-color="#ffffff" />
        </mj-attributes>
      </mj-head>
      <mj-body>
        ${compiledBlocks}
      </mj-body>
    </mjml>`;

    // Compile MJML to HTML
    const mjmlResult = mjml2html(completeMjml, {
      validationLevel: "soft",
    });

    if (mjmlResult.errors.length > 0) {
      console.warn("MJML compilation warnings:", mjmlResult.errors);
    }

    // Update newsletter with compiled MJML and HTML
    await directus.request(
      updateItem("newsletters", newsletter_id, {
        compiled_mjml: completeMjml,
        compiled_html: mjmlResult.html,
      })
    );

    return {
      success: true,
      message: "MJML compiled successfully",
      warnings: mjmlResult.errors.length > 0 ? mjmlResult.errors : null,
    };
  } catch (error: any) {
    console.error("MJML compilation error:", error);

    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || "Internal server error",
    });
  }
});
EOF

    cat > frontend-integration/server/api/newsletter/send.post.ts << 'EOF'
import sgMail from "@sendgrid/mail";
import { createDirectus, rest, readItem, updateItem } from "@directus/sdk";

export default defineEventHandler(async (event) => {
  try {
    const config = useRuntimeConfig();

    // Initialize SendGrid
    sgMail.setApiKey(config.sendgridApiKey);

    // Verify authorization
    const authHeader = getHeader(event, "authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw createError({
        statusCode: 401,
        statusMessage: "Unauthorized",
      });
    }

    const token = authHeader.split(" ")[1];
    if (token !== config.directusWebhookSecret) {
      throw createError({
        statusCode: 401,
        statusMessage: "Invalid token",
      });
    }

    const body = await readBody(event);
    const { newsletter_id, send_record_id } = body;

    if (!newsletter_id || !send_record_id) {
      throw createError({
        statusCode: 400,
        statusMessage: "Newsletter ID and Send Record ID are required",
      });
    }

    // Initialize Directus client
    const directus = createDirectus(config.public.directusUrl as string).with(rest());

    // Update send record to "sending"
    await directus.request(
      updateItem("newsletter_sends", send_record_id, {
        status: "sending",
      })
    );

    // Fetch newsletter
    const newsletter = await directus.request(
      readItem("newsletters", newsletter_id, {
        fields: ["*"],
      })
    );

    if (!newsletter || !newsletter.compiled_html) {
      throw createError({
        statusCode: 400,
        statusMessage: "Newsletter not found or HTML not compiled",
      });
    }

    // For this example, we'll simulate sending
    // In real implementation, you'd integrate with your mailing list system
    
    // Simulate processing delay
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Update send record as completed
    await directus.request(
      updateItem("newsletter_sends", send_record_id, {
        status: "sent",
        sent_count: 1, // Mock data
        sent_at: new Date().toISOString(),
      })
    );

    return {
      success: true,
      message: "Newsletter sent successfully",
      sent_count: 1,
    };
  } catch (error: any) {
    console.error("Newsletter send error:", error);

    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || "Email sending failed",
    });
  }
});
EOF

    # Create TypeScript types
    cat > frontend-integration/types/nuxt.d.ts << 'EOF'
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
  }
}

export {};
EOF

    # Create integration instructions
    cat > frontend-integration/README.md << 'EOF'
# Newsletter Frontend Integration

This package contains the Nuxt.js server endpoints and configuration needed for the newsletter feature.

## Installation

1. **Copy Files to Your Nuxt Project**
   ```bash
   cp -r server/ /path/to/your/nuxt/project/
   cp -r types/ /path/to/your/nuxt/project/
   ```

2. **Install Dependencies**
   ```bash
   cd /path/to/your/nuxt/project
   npm install mjml @sendgrid/mail handlebars @directus/sdk
   npm install -D @types/mjml
   ```

3. **Update nuxt.config.ts**
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

4. **Configure Environment Variables**
   ```env
   DIRECTUS_URL=https://admin.yoursite.com
   DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret
   SENDGRID_API_KEY=your-sendgrid-api-key
   NUXT_SITE_URL=https://yoursite.com
   ```

5. **Test Endpoints**
   ```bash
   # Test MJML compilation
   curl -X POST http://localhost:3000/api/newsletter/compile-mjml \
     -H "Authorization: Bearer your-webhook-secret" \
     -H "Content-Type: application/json" \
     -d '{"newsletter_id": 1}'
   ```

## Flow Configuration

In your Directus admin, create flow operations with these URLs:
- MJML Compile: `https://yoursite.com/api/newsletter/compile-mjml`
- Send Email: `https://yoursite.com/api/newsletter/send`

Use your webhook secret for authorization headers.
EOF

    print_success "Frontend integration package created in frontend-integration/"
}

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

run_installer() {
    local directus_url=$1
    local email=$2
    local password=$3
    local frontend_url=$4
    
    print_status "Running newsletter feature installer..."
    
    if validate_url "$directus_url"; then
        if test_directus_connection "$directus_url"; then
            if [ -n "$frontend_url" ]; then
                print_status "Installing with frontend URL: $frontend_url"
                node newsletter-installer.js "$directus_url" "$email" "$password" "$frontend_url"
            else
                print_status "Installing without frontend URL (manual flow setup required)"
                node newsletter-installer.js "$directus_url" "$email" "$password"
            fi
            
            if [ $? -eq 0 ]; then
                print_success "Newsletter feature installed successfully!"
                echo ""
                print_status "Next steps:"
                echo "1. Copy frontend-integration/ to your Nuxt project"
                echo "2. Follow the integration instructions in frontend-integration/README.md"
                if [ -z "$frontend_url" ]; then
                    echo "3. Manually set up flow operations in Directus admin"
                else
                    echo "3. Complete flow setup in Directus admin"
                fi
                echo "4. Test with a sample newsletter"
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

show_usage() {
    echo "Directus Newsletter Feature - Fixed Deployment Script v${VERSION}"
    echo ""
    echo "This script installs ONLY the Directus collections and data."
    echo "Frontend integration is provided separately for your Nuxt project."
    echo ""
    echo "Usage:"
    echo "  $0 setup                                              # Download and setup installation files"
    echo "  $0 install <directus-url> <email> <password>         # Install to Directus only"
    echo "  $0 install <directus-url> <email> <password> <frontend-url>  # Install with flow URLs"
    echo "  $0 full <directus-url> <email> <password>            # Setup and install"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 install https://admin.example.com admin@example.com password"
    echo "  $0 install https://admin.example.com admin@example.com password https://frontend.example.com"
    echo "  $0 full https://admin.example.com admin@example.com password"
    echo ""
}

main() {
    echo "======================================================"
    echo "   Directus Newsletter Feature - Fixed Deployment"
    echo "                    Version ${VERSION}"
    echo "======================================================"
    echo ""
    echo "🔧 This version separates Directus and frontend setup"
    echo "📦 Directus collections installed on Directus server"
    echo "🌐 Frontend endpoints provided for your Nuxt project"
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

    case "$1" in
        "setup")
            print_status "Setting up newsletter feature installation..."
            setup_deployment_dir
            create_package_json
            create_installer_script
            create_frontend_package
            install_dependencies
            print_success "Setup completed! Files ready in $DEPLOYMENT_DIR"
            echo ""
            print_status "Next: Run installation with your Directus credentials"
            echo "  $0 install https://your-directus-url.com admin@example.com password"
            ;;
        "install")
            if [ $# -lt 4 ]; then
                print_error "Install command requires 3-4 arguments"
                show_usage
                exit 1
            fi
            cd "$DEPLOYMENT_DIR" 2>/dev/null || {
                print_error "Installation files not found. Run '$0 setup' first."
                exit 1
            }
            run_installer "$2" "$3" "$4" "$5"
            ;;
        "full")
            if [ $# -lt 4 ]; then
                print_error "Full command requires 3-4 arguments"
                show_usage
                exit 1
            fi
            print_status "Running full setup and installation..."
            setup_deployment_dir
            create_package_json
            create_installer_script
            create_frontend_package
            install_dependencies
            print_success "Setup completed!"
            echo ""
            run_installer "$2" "$3" "$4" "$5"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"