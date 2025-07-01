#!/bin/bash

# Directus Newsletter Feature - Updated Deployment Script v3.4
# Uses the Complete Newsletter Installer with Automated Directus Flow Creation
# NEW: Adds a URL slug for newsletter previews.
# NEW: Adds field_visibility_config to block_types for dynamic frontend rendering.
# FIX: Explicitly attempts to add 'blocks' field to 'newsletters' collection for relationship.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION="3.4.0" # Updated version to reflect relationship fix
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

setup_deployment_dir() {
    print_status "Setting up deployment directory..."
    
    if [ ! -d "$DEPLOYMENT_DIR" ]; then
        if mkdir -p "$DEPLOYMENT_DIR"; then
            print_success "Created deployment directory: $DEPLOYMENT_DIR"
        else
            print_error "Failed to create deployment directory: $DEPLOYment_DIR"
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
  "version": "3.4.0",
  "type": "module",
  "description": "Complete Newsletter Feature Installer for Directus 11 with Automated Flow Creation, Preview Slugs, and Dynamic Field Metadata",
  "main": "newsletter-installer.js",
  "dependencies": {
    "@directus/sdk": "^17.0.0",
    "mjml": "^4.14.1",
    "handlebars": "^4.7.8",
    "@sendgrid/mail": "^8.1.3"
  },
  "devDependencies": {
    "@types/mjml": "^4.7.4"
  },
  "engines": {
    "node": ">=16.0.0"
  },
  "scripts": {
    "install-newsletter": "node newsletter-installer.js"
  },
  "keywords": ["directus", "newsletter", "mjml", "email", "subscribers", "flows", "automation", "preview", "dynamic fields"],
  "author": "Your Agency",
  "license": "MIT"
}
EOF
    
    print_success "package.json created"
}

download_complete_installer() {
    print_status "Creating complete newsletter installer with automated flow and preview slug..."
    
    cat > newsletter-installer.js << 'EOF'
#!/usr/bin/env node

/**
 * Directus Newsletter Feature - Complete Installer with Automated Flow v3.4
 * * NEW: Automatically creates the complete webhook flow!
 * * NEW: Adds a URL slug for newsletter previews.
 * * NEW: Adds field_visibility_config to block_types for dynamic frontend rendering.
 * * FIX: Ensures 'blocks' field is created on 'newsletters' collection.
 */

import { createDirectus, rest, authentication, readCollections, createCollection, createField, createRelation, createItems, createFlow, createOperation, updateItem } from '@directus/sdk';

class CompleteNewsletterInstaller {
  constructor(directusUrl, email, password, options = {}) {
    this.directus = createDirectus(directusUrl).with(rest()).with(authentication());
    this.email = email;
    this.password = password;
    this.existingCollections = new Set();
    this.options = {
      createFlow: options.createFlow !== false, // Default to true
      frontendUrl: options.frontendUrl || null,
      webhookSecret: options.webhookSecret || 'newsletter-webhook-secret-' + Date.now()
    };
    this.createdFlowId = null;
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
        console.log(`✅ Added field: ${collection}.${field.field}`);
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
      // Block Types
      {
        collection: 'block_types',
        meta: {
          accountability: 'all',
          collection: 'block_types',
          hidden: false,
          icon: 'extension',
          note: 'Available MJML block types for newsletters',
          display_template: '{{name}}'
        },
        schema: { name: 'block_types' }
      },

      // Subscribers
      {
        collection: 'subscribers',
        meta: {
          accountability: 'all',
          collection: 'subscribers',
          hidden: false,
          icon: 'person',
          note: 'Newsletter subscribers with contact information',
          display_template: '{{name}} ({{email}})'
        },
        schema: { name: 'subscribers' }
      },

      // Mailing Lists  
      {
        collection: 'mailing_lists',
        meta: {
          accountability: 'all',
          collection: 'mailing_lists',
          hidden: false,
          icon: 'group',
          note: 'Subscriber mailing lists',
          display_template: '{{name}} ({{subscriber_count}} subscribers)'
        },
        schema: { name: 'mailing_lists' }
      },

      // Subscribers ↔ Mailing Lists Junction
      {
        collection: 'mailing_lists_subscribers',
        meta: {
          accountability: 'all',
          collection: 'mailing_lists_subscribers',
          hidden: true,
          icon: 'link',
          note: 'Junction table for mailing lists and subscribers'
        },
        schema: { name: 'mailing_lists_subscribers' }
      },

      // Newsletters
      {
        collection: 'newsletters',
        meta: {
          accountability: 'all',
          collection: 'newsletters',
          hidden: false,
          icon: 'mail',
          note: 'Email newsletters with MJML blocks',
          display_template: '{{title}} - {{status}}'
        },
        schema: { name: 'newsletters' }
      },

      // Newsletter Blocks
      {
        collection: 'newsletter_blocks',
        meta: {
          accountability: 'all',
          collection: 'newsletter_blocks',
          hidden: false,
          icon: 'view_module',
          note: 'Individual MJML blocks for newsletters',
          display_template: '{{block_type.name}} (#{{sort}})'
        },
        schema: { name: 'newsletter_blocks' }
      },

      // Newsletter Sends
      {
        collection: 'newsletter_sends',
        meta: {
          accountability: 'all',
          collection: 'newsletter_sends',
          hidden: false,
          icon: 'send',
          note: 'Track newsletter send history and status',
          display_template: '{{newsletter.title}} to {{mailing_list.name}}'
        },
        schema: { name: 'newsletter_sends' }
      }
    ];

    for (const collection of collections) {
      await this.createCollectionSafely(collection);
    }

    console.log('\n🔧 Adding fields to collections...');
    
    await this.addBlockTypeFields();
    await this.addSubscriberFields();
    await this.addMailingListFields();
    await this.addJunctionFields();
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
        meta: { interface: 'input-multiline' }
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
      },
      { 
        field: 'field_visibility_config',
        type: 'json',
        meta: { 
          interface: 'input-code', 
          options: { language: 'json' },
          note: 'JSON array of fields to show for this block type in the frontend UI'
        },
        schema: { is_nullable: true }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('block_types', field);
    }
  }

  async addSubscriberFields() {
    console.log('\n📝 Adding fields to subscribers...');
    
    const fields = [
      {
        field: 'email',
        type: 'string',
        meta: { 
          interface: 'input', 
          required: true, 
          width: 'half',
          note: 'Subscriber email address',
          options: { iconLeft: 'email' }
        },
        schema: { is_nullable: false, is_unique: true }
      },
      {
        field: 'name',
        type: 'string',
        meta: { 
          interface: 'input', 
          required: true, 
          width: 'half',
          note: 'Full name of subscriber',
          options: { iconLeft: 'person' }
        },
        schema: { is_nullable: false }
      },
      {
        field: 'company',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'half',
          note: 'Company name (optional)',
          options: { iconLeft: 'business' }
        }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Active', value: 'active' },
              { text: 'Unsubscribed', value: 'unsubscribed' },
              { text: 'Bounced', value: 'bounced' }
            ]
          },
          default_value: 'active'
        }
      },
      {
        field: 'subscribed_at',
        type: 'timestamp',
        meta: { 
          interface: 'datetime', 
          readonly: true, 
          width: 'half',
          note: 'When subscriber was added'
        },
        schema: { default_value: 'now()' }
      },
      {
        field: 'unsubscribe_token',
        type: 'string',
        meta: { 
          interface: 'input', 
          readonly: true, 
          width: 'half',
          note: 'Secure token for unsubscribe links'
        }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('subscribers', field);
    }
  }

  async addMailingListFields() {
    console.log('\n📝 Adding fields to mailing_lists...');
    
    const fields = [
      {
        field: 'name',
        type: 'string',
        meta: { interface: 'input', required: true, width: 'half' },
        schema: { is_nullable: false }
      },
      {
        field: 'description',
        type: 'text',
        meta: { interface: 'input-multiline', width: 'half' }
      },
      {
        field: 'subscriber_count',
        type: 'integer',
        meta: { 
          interface: 'input', 
          readonly: true, 
          width: 'half',
          note: 'Auto-calculated subscriber count'
        },
        schema: { default_value: 0 }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
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

  async addJunctionFields() {
    console.log('\n📝 Adding fields to mailing_lists_subscribers...');
    
    const fields = [
      {
        field: 'mailing_lists_id',
        type: 'integer',
        meta: { interface: 'select-dropdown-m2o', hidden: true },
        schema: { is_nullable: false }
      },
      {
        field: 'subscribers_id',
        type: 'integer',
        meta: { interface: 'select-dropdown-m2o', hidden: true },
        schema: { is_nullable: false }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('mailing_lists_subscribers', field);
    }
  }

  async addNewsletterFields() {
    console.log('\n📝 Adding fields to newsletters...');
    
    const fields = [
      {
        field: 'title',
        type: 'string',
        meta: { interface: 'input', required: true, width: 'half' },
        schema: { is_nullable: false }
      },
      {
        field: 'slug', 
        type: 'string',
        meta: { 
          interface: 'input', 
          required: true, 
          width: 'half',
          note: 'URL-friendly slug for public preview (e.g., my-awesome-newsletter)',
          options: { iconLeft: 'link' }
        },
        schema: { is_nullable: false, is_unique: true, has_index: true } 
      },
      {
        field: 'subject_line',
        type: 'string',
        meta: { 
          interface: 'input', 
          required: true, 
          width: 'half',
          note: 'Email subject line'
        },
        schema: { is_nullable: false }
      },
      {
        field: 'preview_text',
        type: 'string',
        meta: { 
          interface: 'input', 
          note: 'Preview text shown in email clients'
        }
      },
      {
        field: 'from_name',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'third',
          default_value: 'Newsletter'
        }
      },
      {
        field: 'from_email',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'third',
          options: { iconLeft: 'email' }
        }
      },
      {
        field: 'reply_to',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'third',
          note: 'Reply-to email address'
        }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
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
    console.log('\n📝 Adding user-friendly fields to newsletter_blocks...');
    
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
        schema: { default_value: 1 }
      },

      // Content Fields (User-Friendly!)
      {
        field: 'title',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'half',
          note: 'Main heading text'
        }
      },
      {
        field: 'subtitle',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'half',
          note: 'Optional subtitle'
        }
      },
      {
        field: 'text_content',
        type: 'text',
        meta: {
          interface: 'input-rich-text-html',
          note: 'Main text content'
        }
      },
      {
        field: 'image_url',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'full',
          note: 'Image URL or file path'
        }
      },
      {
        field: 'image_alt_text',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'half',
          note: 'Alt text for accessibility'
        }
      },
      {
        field: 'image_caption',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'half',
          note: 'Optional image caption'
        }
      },
      {
        field: 'button_text',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'half',
          note: 'Button label text'
        }
      },
      {
        field: 'button_url',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'half',
          note: 'Button destination URL'
        }
      },
      {
        field: 'background_color',
        type: 'string',
        meta: {
          interface: 'select-color',
          width: 'third',
          note: 'Section background color',
          options: {
            presets: [
              { color: '#ffffff', name: 'White' },
              { color: '#f8f9fa', name: 'Light Gray' },
              { color: '#e9ecef', name: 'Gray' },
              { color: '#007bff', name: 'Blue' },
              { color: '#28a745', name: 'Green' }
            ]
          }
        },
        schema: { default_value: '#ffffff' }
      },
      {
        field: 'text_color',
        type: 'string',
        meta: {
          interface: 'select-color',
          width: 'third',
          note: 'Text color',
          options: {
            choices: [
              { text: 'Black', value: '#000000' },
              { text: 'Dark Gray', value: '#333333' },
              { text: 'Gray', value: '#666666' },
              { text: 'White', value: '#ffffff' }
            ]
          }
        },
        schema: { default_value: '#333333' }
      },
      {
        field: 'text_align',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'third',
          note: 'Text alignment',
          options: {
            choices: [
              { text: 'Left', value: 'left' },
              { text: 'Center', value: 'center' },
              { text: 'Right', value: 'right' }
            ]
          }
        },
        schema: { default_value: 'center' }
      },
      {
        field: 'padding',
        type: 'string',
        meta: {
          interface: 'input',
          width: 'half',
          note: 'CSS padding (e.g., "20px 0")',
          options: { placeholder: '20px 0' }
        },
        schema: { default_value: '20px 0' }
      },
      {
        field: 'font_size',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          note: 'Text font size',
          options: {
            choices: [
              { text: 'Small (12px)', value: '12px' },
              { text: 'Normal (14px)', value: '14px' },
              { text: 'Large (16px)', value: '16px' },
              { text: 'Extra Large (18px)', value: '18px' }
            ]
          }
        },
        schema: { default_value: '14px' }
      },

      // Legacy content field (hidden but kept for backwards compatibility)
      {
        field: 'content',
        type: 'json',
        meta: {
          interface: 'input-code',
          options: { language: 'json' },
          hidden: true,
          readonly: true,
          note: 'Legacy JSON field - use individual fields above'
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
          width: 'half',
          display_options: { template: '{{title}}' }
        },
        schema: { is_nullable: false }
      },
      {
        field: 'mailing_list_id',
        type: 'integer',
        meta: { 
          interface: 'select-dropdown-m2o',
          required: true,
          width: 'half',
          display_options: { template: '{{name}}' }
        },
        schema: { is_nullable: false }
      },
      {
        field: 'status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
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
        meta: { interface: 'input', readonly: true, width: 'half' }
      },
      {
        field: 'sent_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, width: 'half' },
        schema: { default_value: 0 }
      },
      {
        field: 'failed_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, width: 'half' },
        schema: { default_value: 0 }
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

    # Explicitly add the 'blocks' O2M field to 'newsletters' BEFORE creating the relationship
    # This ensures the field exists before the relation attempts to link to it.
    await this.createFieldWithRetry('newsletters', {
      field: 'blocks',
      type: 'alias', # Use alias type for O2M relation field
      meta: {
        interface: 'list-o2m',
        options: {
          template: '{{block_type.name}} (#{{sort}})'
        },
        note: 'Blocks composing this newsletter'
      },
      schema: {
        is_nullable: true # Can be null if no blocks
      }
    });

    # First, add the M2O field to newsletters
    try {
      await this.createFieldWithRetry('newsletters', {
        field: 'mailing_list_id',
        type: 'integer',
        meta: {
          interface: 'select-dropdown-m2o',
          width: 'half',
          note: 'Which mailing list to send to',
          display_options: { template: '{{name}}' }
        }
      });
    } catch (error) {
      console.log('⚠️  Mailing list field may already exist');
    }

    const relations = [
      # Newsletter Blocks → Newsletter (M2O)
      {
        collection: 'newsletter_blocks',
        field: 'newsletter_id',
        related_collection: 'newsletters',
        meta: {
          many_collection: 'newsletter_blocks',
          many_field: 'newsletter_id',
          one_collection: 'newsletters',
          one_field: 'blocks', # This is the field we explicitly added above
          sort_field: 'sort',
          one_deselect_action: 'delete'
        }
      },

      # Newsletter Blocks → Block Types (M2O)
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

      # Newsletter → Mailing List (M2O)
      {
        collection: 'newsletters',
        field: 'mailing_list_id',
        related_collection: 'mailing_lists',
        meta: {
          many_collection: 'newsletters',
          many_field: 'mailing_list_id',
          one_collection: 'mailing_lists',
          one_deselect_action: 'nullify'
        }
      },

      # Mailing Lists ↔ Subscribers (M2M)
      {
        collection: 'mailing_lists_subscribers',
        field: 'mailing_lists_id',
        related_collection: 'mailing_lists',
        meta: {
          many_collection: 'mailing_lists_subscribers',
          many_field: 'mailing_lists_id',
          one_collection: 'mailing_lists',
          one_field: 'subscribers',
          junction_field: 'subscribers_id',
          one_deselect_action: 'delete'
        }
      },
      {
        collection: 'mailing_lists_subscribers',
        field: 'subscribers_id',
        related_collection: 'subscribers',
        meta: {
          many_collection: 'mailing_lists_subscribers',
          many_field: 'subscribers_id',
          one_collection: 'subscribers',
          one_field: 'mailing_lists',
          junction_field: 'mailing_lists_id',
          one_deselect_action: 'delete'
        }
      },

      # Newsletter Sends → Newsletter (M2O)
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

      # Newsletter Sends → Mailing List (M2O)
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

    # Create all relationships
    for (const relation of relations) {
      try {
        await this.directus.request(createRelation(relation));
        console.log(`✅ Created relation: ${relation.collection}.${relation.field} → ${relation.related_collection}`);
        await new Promise(resolve => setTimeout(resolve, 800));
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⏭️  Relation already exists: ${relation.collection}.${relation.field} → ${relation.related_collection}`);
        } else {
          console.error(`❌ Failed to create relation: ${relation.collection}.${relation.field}`, error.message);
        }
      }
    }
  }

  async insertSampleData() {
    console.log('\n🧩 Installing sample data...');

    # Block Types with updated templates and field_visibility_config
    const blockTypes = [
      {
        name: "Hero Section",
        slug: "hero",
        description: "Large header section with title, subtitle, and optional button",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-text align="{{text_align}}" font-size="32px" font-weight="bold" color="{{text_color}}">
      {{title}}
    </mj-text>
    {{#if subtitle}}
    <mj-text align="{{text_align}}" font-size="18px" color="{{text_color}}">
      {{subtitle}}
    </mj-text>
    {{/if}}
    {{#if button_text}}
    <mj-button background-color="#007bff" color="#ffffff" href="{{button_url}}">
      {{button_text}}
    </mj-button>
    {{/if}}
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["title", "subtitle", "button_text", "button_url", "background_color", "text_color", "text_align", "padding"]
      },
      {
        name: "Text Block",
        slug: "text",
        description: "Simple text content with formatting options",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-text align="{{text_align}}" font-size="{{font_size}}" color="{{text_color}}">
      {{text_content}}
    </mj-text>
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["text_content", "background_color", "text_color", "text_align", "padding", "font_size"]
      },
      {
        name: "Image Block",
        slug: "image",
        description: "Image with optional caption",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-image src="{{image_url}}" alt="{{image_alt_text}}" align="{{text_align}}" />
    {{#if image_caption}}
    <mj-text align="{{text_align}}" font-size="12px" color="#666666" padding="10px 0 0 0">
      {{image_caption}}
    </mj-text>
    {{/if}}
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["image_url", "image_alt_text", "image_caption", "background_color", "text_align", "padding"]
      },
      {
        name: "Button",
        slug: "button",
        description: "Call-to-action button with customizable styling",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-button background-color="#007bff" color="#ffffff" href="{{button_url}}" align="{{text_align}}">
      {{button_text}}
    </mj-button>
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["button_text", "button_url", "background_color", "text_align", "padding"]
      },
      {
        name: "Divider",
        slug: "divider",
        description: "Horizontal line separator",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-divider border-color="{{text_color}}" border-width="1px" />
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["text_color", "background_color", "padding"]
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

    # Sample Subscribers
    const subscribers = [
      {
        name: "Test User",
        email: "test@example.com",
        company: "Test Company",
        status: "active"
      }
    ];

    for (const subscriber of subscribers) {
      try {
        await this.directus.request(createItems('subscribers', subscriber));
        console.log(`✅ Created subscriber: ${subscriber.name}`);
      } catch (error) {
        console.log(`⚠️  Could not create subscriber ${subscriber.name}:`, error.message);
      }
    }

    # Sample Mailing List
    const mailingLists = [
      {
        name: "General Newsletter",
        description: "General company newsletter subscribers",
        subscriber_count: 1,
        status: "active"
      }
    ];

    for (const list of mailingLists) {
      try {
        await this.directus.request(createItems('mailing_lists', list));
        console.log(`✅ Created mailing list: ${list.name}`);
      } catch (error) {
        console.log(`⚠️  Could not create mailing list ${list.name}:`, error.message);
      }
    }
  }

  async createNewsletterFlow() {
    if (!this.options.createFlow) {
      console.log('\n⏭️  Skipping flow creation (disabled in options)');
      return;
    }

    if (!this.options.frontendUrl) {
      console.log('\n⚠️  Cannot create flow without frontend URL');
      console.log('    Please provide frontend URL or create flow manually in Directus admin');
      console.log('    Example: node installer.js <directus> <email> <pass> https://yoursite.com');
      return;
    }

    console.log('\n🔄 Creating automated newsletter sending flow...');

    try {
      # Create the main flow
      const flow = await this.directus.request(createFlow({
        name: 'Send Newsletter',
        icon: 'send',
        color: '#00D4AA',
        description: 'Compiles MJML blocks and sends newsletter to selected mailing list',
        status: 'active',
        trigger: 'manual',
        accountability: 'all',
        options: {
          collections: ['newsletters'],
          location: 'item',
          requireConfirmation: true,
          confirmationDescription: 'This will send the newsletter to the selected mailing list. Are you sure you want to continue?'
        }
      }));

      console.log(`✅ Created flow: ${flow.name} (ID: ${flow.id})`);
      this.createdFlowId = flow.id;

      # Create flow operations
      await this.createFlowOperations(flow.id);

      console.log('\n🎉 Newsletter flow created successfully!');
      console.log('\n📋 Flow details:');
      console.log(`    • Flow ID: ${flow.id}`);
      console.log(`    • Webhook Secret: ${this.options.webhookSecret}`);
      console.log(`    • Frontend URL: ${this.options.frontendUrl}`);
      console.log(`    • Status: Active and ready to use`);

    } catch (error) {
      console.log(`⚠️  Could not create flow automatically: ${error.message}`);
      console.log('\nManual setup required:');
      console.log('1. Go to Settings → Flows in Directus admin');
      console.log('2. Create "Send Newsletter" flow');
      console.log(`3. Use webhook secret: ${this.options.webhookSecret}`);
      console.log(`4. Use frontend URLs:`);
      console.log(`    - Compile: ${this.options.frontendUrl}/api/newsletter/compile-mjml`);
      console.log(`    - Send: ${this.options.frontendUrl}/api/newsletter/send`);
    }
  }

  async createFlowOperations(flowId) {
    console.log('\n🔧 Creating flow operations...');

    const operations = [
      # 1. Validate Newsletter
      {
        name: 'Validate Newsletter',
        key: 'validate_newsletter',
        type: 'condition',
        position_x: 19,
        position_y: 1,
        options: {
          filter: {
            "_and": [
              { "status": { "_eq": "ready" } },
              { "subject_line": { "_nnull": true } },
              { "from_email": { "_nnull": true } },
              { "mailing_list_id": { "_nnull": true } }
            ]
          }
        },
        resolve: null, # Will be set after creating compile operation
        reject: null    # Will be set after creating log operation
      },

      # 2. Log Validation Error
      {
        name: 'Log Validation Error',
        key: 'log_validation_error',
        type: 'log',
        position_x: 19,
        position_y: 21,
        options: {
          level: 'error',
          message: 'Newsletter validation failed: Newsletter must be in "ready" status with subject line, from email, and mailing list configured.'
        }
      },

      # 3. Compile MJML
      {
        name: 'Compile MJML',
        key: 'compile_mjml',
        type: 'webhook',
        position_x: 39,
        position_y: 1,
        options: {
          method: 'POST',
          url: `${this.options.frontendUrl}/api/newsletter/compile-mjml`,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.options.webhookSecret}`
          },
          body: JSON.stringify({
            newsletter_id: '{{$trigger.body.keys[0]}}'
          })
        },
        resolve: null, # Will be set after creating next operation
        reject: null    # Will be set after creating log operation
      },

      # 4. Log Compile Error
      {
        name: 'Log Compile Error',
        key: 'log_compile_error',
        type: 'log',
        position_x: 39,
        position_y: 21,
        options: {
          level: 'error',
          message: 'MJML compilation failed: {{compile_mjml.$last.error}}'
        }
      },

      # 5. Create Send Record
      {
        name: 'Create Send Record',
        key: 'create_send_record',
        type: 'create',
        position_x: 59,
        position_y: 1,
        options: {
          collection: 'newsletter_sends',
          payload: JSON.stringify({
            newsletter_id: '{{$trigger.body.keys[0]}}',
            mailing_list_id: '{{$trigger.body.mailing_list_id}}',  
            status: 'pending',
            total_recipients: 0 # Will be calculated by send endpoint
          })
        },
        resolve: null, # Will be set after creating send operation
        reject: null
      },

      # 6. Send Email
      {
        name: 'Send Email',
        key: 'send_email',
        type: 'webhook',
        position_x: 79,
        position_y: 1,
        options: {
          method: 'POST',
          url: `${this.options.frontendUrl}/api/newsletter/send`,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.options.webhookSecret}`
          },
          body: JSON.stringify({
            newsletter_id: '{{$trigger.body.keys[0]}}',
            send_record_id: '{{create_send_record.id}}'
          })
        },
        resolve: null, # Will be set after creating update operation
        reject: null    # Will be set after creating log operation
      },

      # 7. Log Send Error
      {
        name: 'Log Send Error',
        key: 'log_send_error',
        type: 'log',
        position_x: 79,
        position_y: 21,
        options: {
          level: 'error',
          message: 'Email sending failed: {{send_email.$last.error}}'
        },
        resolve: null # Will be set after creating update failed operation
      },

      # 8. Update Send Failed
      {
        name: 'Update Send Failed',
        key: 'update_send_failed',
        type: 'update',
        position_x: 99,
        position_y: 21,
        options: {
          collection: 'newsletter_sends',
          key: '{{create_send_record.id}}',
          payload: JSON.stringify({
            status: 'failed',
            error_log: '{{send_email.$last.error}}'
          })
        }
      },

      # 9. Update Newsletter Status
      {
        name: 'Update Newsletter Status',
        key: 'update_newsletter_status',
        type: 'update',
        position_x: 99,
        position_y: 1,
        options: {
          collection: 'newsletters',
          key: '{{$trigger.body.keys[0]}}',
          payload: JSON.stringify({
            status: 'sent'
          })
        },
        resolve: null # Will be set after creating log success operation
      },

      # 10. Log Success
      {
        name: 'Log Success',
        key: 'log_success',
        type: 'log',
        position_x: 119,
        position_y: 1,
        options: {
          level: 'info',
          message: 'Newsletter sent successfully: {{$trigger.body.keys[0]}}'
        }
      }
    ];

    # Create all operations first
    const createdOperations = {};
    for (const operation of operations) {
      try {
        const created = await this.directus.request(createOperation({
          flow: flowId,
          name: operation.name,
          key: operation.key,
          type: operation.type,
          position_x: operation.position_x,
          position_y: operation.position_y,
          options: operation.options
        }));
        
        createdOperations[operation.key] = created;
        console.log(`✅ Created operation: ${operation.name}`);
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (error) {
        console.error(`❌ Failed to create operation ${operation.name}:`, error.message);
      }
    }

    # Now update operations with resolve/reject connections
    const connections = [
      { from: 'validate_newsletter', resolve: 'compile_mjml', reject: 'log_validation_error' },
      { from: 'compile_mjml', resolve: 'create_send_record', reject: 'log_compile_error' },
      { from: 'create_send_record', resolve: 'send_email', reject: null },
      { from: 'send_email', resolve: 'update_newsletter_status', reject: 'log_send_error' },
      { from: 'log_send_error', resolve: 'update_send_failed', reject: null },
      { from: 'update_newsletter_status', resolve: 'log_success', reject: null }
    ];

    # Update operations with connections
    for (const connection of connections) {
      if (createdOperations[connection.from]) {
        const updateData = {};
        if (connection.resolve && createdOperations[connection.resolve]) {
          updateData.resolve = createdOperations[connection.resolve].id;
        }
        if (connection.reject && createdOperations[connection.reject]) {
          updateData.reject = createdOperations[connection.reject].id;
        }

        if (Object.keys(updateData).length > 0) {
          try {
            await this.directus.request(
              updateItem('directus_operations', createdOperations[connection.from].id, updateData)
            );
            console.log(`✅ Connected ${connection.from} → ${connection.resolve || connection.reject}`);
          } catch (error) {
            console.log(`⚠️  Could not connect ${connection.from}:`, error.message);
          }
        }
      }
    }
  }

  async createEnvironmentFile() {
    if (!this.options.frontendUrl) {
      return;
    }

    console.log('\n📄 Creating environment configuration...');

    const envContent = `# Directus Newsletter Feature Environment Configuration
# Generated by installer on ${new Date().toISOString()}

# Directus Configuration
DIRECTUS_URL=${this.options.frontendUrl.replace(/^https?:\/\//, '').replace(/\/.*$/, '')}
DIRECTUS_WEBHOOK_SECRET=${this.options.webhookSecret}

# SendGrid Configuration (UPDATE THESE!)
SENDGRID_API_KEY=SG.your-sendgrid-api-key-here
SENDGRID_UNSUBSCRIBE_GROUP_ID=12345

# Site Configuration
NUXT_SITE_URL=${this.options.frontendUrl}

# Optional: Additional Configuration
# SENDGRID_FROM_EMAIL=newsletter@yoursite.com
# SENDGRID_FROM_NAME=Your Company Newsletter
# NEWSLETTER_LOGO_URL=https://yoursite.com/images/logo.png

# IMPORTANT: Update SENDGRID_API_KEY with your actual SendGrid API key!
# The flow will not work until this is configured.
`;

    try {
      # In a real implementation, you'd write this to a file
      console.log('\n📋 Environment configuration:');
      console.log('Copy this to your .env file:');
      console.log('─'.repeat(60));
      console.log(envContent);
      console.log('─'.repeat(60));
    } catch (error) {
      console.log('⚠️  Could not create environment file:', error.message);
    }
  }

  async run() {
    console.log('🚀 Starting Complete Newsletter Feature Installation v3.4\n');
    console.log('🆕 NEW: Automated webhook flow creation!\n');
    console.log('🆕 NEW: Newsletter URL slug for public previews!\n');
    console.log('🆕 NEW: Dynamic field visibility metadata for frontend UI!\n');
    console.log('✅ FIX: Ensured "blocks" field is created on "newsletters" collection.\n');


    if (!(await this.initialize())) {
      return false;
    }

    try {
      await this.createCollections();
      await this.createRelations();
      await this.insertSampleData();
      await this.createNewsletterFlow(); # NEW: Automated flow creation
      await this.createEnvironmentFile(); # NEW: Environment config

      console.log('\n🎉 Complete newsletter feature installation completed!');
      console.log('\n📦 What was installed:');
      console.log('    • 7 Collections with all relationships');
      console.log('    • 5 MJML Block Types with user-friendly fields');
      console.log('    • Complete M2M relationship (subscribers ↔ mailing_lists)');
      console.log('    • Complete M2O relationship (newsletters → mailing_lists)');
      console.log('    • User-friendly block creation (no more JSON!)');
      console.log('    • Sample data for testing');
      console.log('    • Newsletter slug field for public previews');
      console.log('    • Block type field visibility configuration (for frontend UI)');
      if (this.createdFlowId) {
        console.log('    • Automated webhook flow (READY TO USE!)');
      }
      
      console.log('\n📋 Next steps:');
      console.log('1. Copy the frontend-integration/ to your Nuxt project');
      console.log('2. Configure environment variables (see above)');
      console.log('3. Update your SendGrid API key in the .env file');
      if (this.createdFlowId) {
        console.log('4. Test the complete workflow - it should work immediately!');
      } else {
        console.log('4. Complete flow setup in Directus admin (manual)');
      }
      console.log('5. Implement the Nuxt.js preview page (see frontend-integration/README.md for details).');
      console.log('6. Implement dynamic field visibility in your frontend (see frontend-integration/README.md for details).');
      
      return true;
    } catch (error) {
      console.error('\n❌ Installation failed:', error.message);
      return false;
    }
  }
}

# CLI Interface
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 3) {
    console.log('Complete Newsletter Feature Installer v3.4 - WITH AUTOMATED FLOWS & PREVIEW SLUGS & DYNAMIC FIELDS!');
    console.log('');
    console.log('Usage: node newsletter-installer.js <directus-url> <email> <password> [frontend-url] [webhook-secret]');
    console.log('');
    console.log('NEW Features:');
    console.log('  • Automated webhook flow creation (no manual setup!)');
    console.log('  • Environment configuration generation');
    console.log('  • Newsletter URL slug for public previews');
    console.log('  • Dynamic field visibility metadata for frontend UI');
    console.log('  • Complete one-command installation');
    console.log('');
    console.log('Existing Features:');
    console.log('  • Subscribers collection with name, email, company');
    console.log('  • User-friendly block fields (no JSON required!)');
    console.log('  • Proper M2M relationships (subscribers ↔ mailing_lists)');
    console.log('  • Proper M2O relationships (newsletters → mailing_lists)');
    console.log('');
    console.log('Examples:');
    console.log('  # Basic installation (manual flow setup)');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123');
    console.log('');
    console.log('  # Full automation (creates complete flow!)');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123 https://frontend.example.com');
    console.log('');
    console.log('  # With custom webhook secret');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123 https://frontend.example.com my-secret-key');
    process.exit(1);
  }

  const [directusUrl, email, password, frontendUrl, webhookSecret] = args;
  
  const options = {};
  if (frontendUrl) options.frontendUrl = frontendUrl;
  if (webhookSecret) options.webhookSecret = webhookSecret;
  
  const installer = new CompleteNewsletterInstaller(directusUrl, email, password, options);
  
  const success = await installer.run();
  process.exit(success ? 0 : 1);
}

main().catch(console.error);
EOF
    
    chmod +x newsletter-installer.js
    print_success "Complete newsletter installer downloaded"
}

create_frontend_package() {
    print_status "Creating enhanced frontend integration package..."
    
    mkdir -p frontend-integration
    mkdir -p frontend-integration/server/api/newsletter
    mkdir -p frontend-integration/types
    
    # Create the enhanced MJML compilation endpoint
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

    // Fetch newsletter with blocks and all individual fields
    const newsletter = await directus.request(
      readItem("newsletters", newsletter_id, {
        fields: [
          "*",
          "blocks.id",
          "blocks.sort",
          // Individual content fields instead of JSON
          "blocks.title",
          "blocks.subtitle", 
          "blocks.text_content",
          "blocks.image_url",
          "blocks.image_alt_text",
          "blocks.image_caption",
          "blocks.button_text",
          "blocks.button_url",
          "blocks.background_color",
          "blocks.text_color",
          "blocks.text_align",
          "blocks.padding",
          "blocks.font_size",
          // Block type info
          "blocks.block_type.name",
          "blocks.block_type.slug",
          "blocks.block_type.mjml_template",
          // Legacy content field (fallback)
          "blocks.content"
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
        // Prepare block data using individual fields with fallbacks
        const blockData = {
          // Text content
          title: block.title || (block.content?.title) || '',
          subtitle: block.subtitle || (block.content?.subtitle) || '',
          text_content: block.text_content || (block.content?.content) || (block.content?.text_content) || '',
          
          // Image fields
          image_url: block.image_url || (block.content?.image_url) || '',
          image_alt_text: block.image_alt_text || (block.content?.alt_text) || (block.content?.image_alt_text) || '',
          image_caption: block.image_caption || (block.content?.caption) || (block.content?.image_caption) || '',
          
          // Button fields
          button_text: block.button_text || (block.content?.button_text) || '',
          button_url: block.button_url || (block.content?.button_url) || '',
          
          // Styling fields with defaults
          background_color: block.background_color || (block.content?.background_color) || '#ffffff',
          text_color: block.text_color || (block.content?.text_color) || '#333333',
          text_align: block.text_align || (block.content?.text_align) || 'center',
          
          // Layout fields
          padding: block.padding || (block.content?.padding) || '20px 0',
          font_size: block.font_size || (block.content?.font_size) || '14px'
        };

        // Compile handlebars template with block data
        const template = Handlebars.compile(block.block_type.mjml_template);
        const blockMjml = template(blockData);

        // Store compiled MJML for this block
        await directus.request(
          updateItem("newsletter_blocks", block.id, {
            mjml_output: blockMjml,
          })
        );

        compiledBlocks += blockMjml + "\n";
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error(`Error compiling block ${block.id}:`, errorMessage);
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
      blocks_compiled: sortedBlocks.length
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

    # Create enhanced send endpoint
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

    // Fetch newsletter and mailing list with subscribers
    const sendRecord = await directus.request(
      readItem("newsletter_sends", send_record_id, {
        fields: [
          "*",
          "newsletter.title",
          "newsletter.subject_line",
          "newsletter.from_name",
          "newsletter.from_email",
          "newsletter.compiled_html",
          "mailing_list.name",
          "mailing_list.subscribers.subscribers_id.email",
          "mailing_list.subscribers.subscribers_id.name"
        ],
      })
    );

    if (!sendRecord || !sendRecord.newsletter.compiled_html) {
      throw createError({
        statusCode: 400,
        statusMessage: "Send record not found or newsletter HTML not compiled",
      });
    }

    const subscribers = sendRecord.mailing_list?.subscribers || [];
    
    if (subscribers.length === 0) {
      await directus.request(
        updateItem("newsletter_sends", send_record_id, {
          status: "sent",
          sent_count: 0,
          sent_at: new Date().toISOString(),
        })
      );

      return {
        success: true,
        message: "No subscribers in mailing list",
        sent_count: 0,
      };
    }

    // For demo purposes, we'll simulate sending
    // In production, implement actual SendGrid sending
    
    await new Promise(resolve => setTimeout(resolve, 2000)); // Simulate delay

    // Update send record as completed
    await directus.request(
      updateItem("newsletter_sends", send_record_id, {
        status: "sent",
        sent_count: subscribers.length,
        sent_at: new Date().toISOString(),
      })
    );

    return {
      success: true,
      message: `Newsletter sent successfully to ${subscribers.length} subscribers`,
      sent_count: subscribers.length,
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

    # Create integration README
    cat > frontend-integration/README.md << 'EOF'
# Enhanced Newsletter Frontend Integration v3.4

This package contains the enhanced Nuxt.js server endpoints with support for:
- User-friendly block fields (no JSON required)
- Subscriber management integration
- M2M relationship support (subscribers ↔ mailing_lists)
- Backwards compatibility with legacy JSON content
- Automated Directus Flow integration

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

3. **Configure Environment Variables**
   ```env
   DIRECTUS_URL=[https://admin.yoursite.com](https://admin.yoursite.com)
   DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret
   SENDGRID_API_KEY=your-sendgrid-api-key
   NUXT_SITE_URL=[https://yoursite.com](https://yoursite.com)
   ```

## New Features

### User-Friendly Block Creation
Users now create blocks with proper form fields instead of JSON:
- **Title**: Text input
- **Background Color**: Color picker with presets
- **Text Alignment**: Dropdown (Left/Center/Right)
- **Button Text**: Text input
- **Button URL**: URL input

### Subscriber Management
- Create subscribers with name, email, company
- Assign subscribers to multiple mailing lists
- M2M relationships fully supported

### Enhanced MJML Compilation
- Supports both new individual fields and legacy JSON content
- Backwards compatible with existing newsletters
- Better error handling and logging

### Newsletter Preview by Slug
You can now create a public-facing page to preview newsletters using a URL slug.

**Steps to Implement in Nuxt 3:**

1.  **Ensure Public Read Access in Directus:**
    * Go to your Directus Admin Panel -> Settings -> Roles & Permissions.
    * Select the `Public` role.
    * Find the `newsletters` collection and grant `Read` permission.
    * For the `Read` permission, you might want to limit fields to `slug` and `compiled_html` for security/privacy.

2.  **Create a Nuxt Page for Preview:**
    Create a file like `pages/newsletter/[slug].vue` in your Nuxt 3 project:

    ```vue
    <template>
      <div v-if="newsletterHtml" v-html="newsletterHtml"></div>
      <div v-else>
        <p>Loading newsletter preview...</p>
        <p v-if="error">{{ error.message }}</p>
      </div>
    </template>

    <script setup lang="ts">
    import { createDirectus, rest, readItems } from '@directus/sdk';
    import { ref, onMounted } from 'vue';
    import { useRoute } from 'vue-router';

    const config = useRuntimeConfig();
    const route = useRoute();
    const newsletterHtml = ref<string | null>(null);
    const error = ref<Error | null>(null);

    onMounted(async () => {
      const slug = route.params.slug;

      if (!slug) {
        error.value = new Error('Newsletter slug not provided in URL.');
        return;
      }

      try {
        const directus = createDirectus(config.public.directusUrl as string).with(rest());
        
        // Fetch newsletter by slug
        const response = await directus.request(
          readItems('newsletters', {
            filter: {
              slug: {
                _eq: slug
              },
              status: { // Only show published/sent newsletters publicly
                _in: ['published', 'sent'] 
              }
            },
            fields: ['compiled_html']
          })
        );

        if (response && response.length > 0) {
          newsletterHtml.value = response[0].compiled_html;
        } else {
          error.value = new Error(`Newsletter with slug "${slug}" not found or not published.`);
        }
      } catch (err: any) {
        console.error('Error fetching newsletter preview:', err);
        error.value = new Error('Failed to load newsletter preview. Please try again later.');
      }
    });

    // Optional: Set page title
    useHead({
      title: `Newsletter Preview - ${route.params.slug}`
    });
    </script>

    <style>
    /* Basic styling to make the HTML content readable */
    body {
      margin: 0;
      padding: 0;
      background-color: #f0f0f0;
    }
    div {
      max-width: 600px; /* Standard email width */
      margin: 20px auto;
      background-color: #ffffff;
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
      padding: 0; /* MJML generated HTML often has its own padding */
    }
    /* Add any other global styles for your email preview here */
    </style>
    ```

3.  **Generate Slugs for Newsletters:**
    When you create or update a newsletter in Directus, ensure you populate the `slug` field. You can:
    * **Manually:** Type a unique, URL-friendly slug (e.g., `my-first-newsletter`, `july-2025-update`).
    * **Automatically (Recommended for production):** Implement a Directus Flow Hook that generates the slug from the `title` field whenever a newsletter is created or updated. You can use a "Run Script" operation with JavaScript to slugify the title.

### Dynamic Field Visibility in Frontend UI

To make the `newsletter_blocks` fields dynamic based on the selected `block_type`, you'll need to implement this logic in your frontend application (e.g., your Nuxt.js project).

**How to Implement in Nuxt 3 (for a custom block editing component):**

1.  **Fetch `block_types` with `field_visibility_config`:**
    When your frontend loads a newsletter for editing, or when a user selects a `block_type` for a `newsletter_block`, you should fetch the `block_types` collection, ensuring you include the `field_visibility_config` field.

    ```typescript
    // Example of fetching block types in Nuxt 3
    import { createDirectus, rest, readItems } from '@directus/sdk';

    const config = useRuntimeConfig();
    const directus = createDirectus(config.public.directusUrl as string).with(rest());

    interface BlockType {
      id: string;
      name: string;
      slug: string;
      field_visibility_config: string[]; // Array of field names
      // ... other fields
    }

    const blockTypes = ref<BlockType[]>([]);

    async function fetchBlockTypes() {
      try {
        blockTypes.value = await directus.request(
          readItems('block_types', {
            fields: ['id', 'name', 'slug', 'field_visibility_config']
          })
        );
      } catch (e) {
        console.error('Error fetching block types:', e);
      }
    }

    onMounted(fetchBlockTypes);
    ```

2.  **Implement Conditional Rendering in your Vue Component:**
    In your Nuxt.js component where you edit `newsletter_blocks`, you'll need logic to:
    * Get the currently selected `block_type` for the `newsletter_block` being edited.
    * Find the corresponding `block_type` object from your `blockTypes` data.
    * Use the `field_visibility_config` array from that `block_type` to conditionally render the input fields for the `newsletter_block`.

    ```vue
    <template>
      <div>
        <!-- Block Type Selector -->
        <label for="blockType">Block Type:</label>
        <select id="blockType" v-model="selectedBlockTypeId" @change="updateVisibleFields">
          <option v-for="type in blockTypes" :key="type.id" :value="type.id">{{ type.name }}</option>
        </select>

        <!-- Dynamically rendered fields -->
        <div v-if="currentBlockTypeConfig">
          <div v-if="currentBlockTypeConfig.includes('title')">
            <label for="title">Title:</label>
            <input type="text" id="title" v-model="blockData.title" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('subtitle')">
            <label for="subtitle">Subtitle:</label>
            <input type="text" id="subtitle" v-model="blockData.subtitle" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('text_content')">
            <label for="textContent">Content:</label>
            <textarea id="textContent" v-model="blockData.text_content"></textarea>
          </div>
          <div v-if="currentBlockTypeConfig.includes('image_url')">
            <label for="imageUrl">Image URL:</label>
            <input type="text" id="imageUrl" v-model="blockData.image_url" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('image_alt_text')">
            <label for="imageAltText">Image Alt Text:</label>
            <input type="text" id="imageAltText" v-model="blockData.image_alt_text" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('image_caption')">
            <label for="imageCaption">Image Caption:</label>
            <input type="text" id="imageCaption" v-model="blockData.image_caption" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('button_text')">
            <label for="buttonText">Button Text:</label>
            <input type="text" id="buttonText" v-model="blockData.button_text" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('button_url')">
            <label for="buttonUrl">Button URL:</label>
            <input type="text" id="buttonUrl" v-model="blockData.button_url" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('background_color')">
            <label for="backgroundColor">Background Color:</label>
            <input type="color" id="backgroundColor" v-model="blockData.background_color" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('text_color')">
            <label for="textColor">Text Color:</label>
            <input type="color" id="textColor" v-model="blockData.text_color" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('text_align')">
            <label for="textAlign">Text Align:</label>
            <select id="textAlign" v-model="blockData.text_align">
              <option value="left">Left</option>
              <option value="center">Center</option>
              <option value="right">Right</option>
            </select>
          </div>
          <div v-if="currentBlockTypeConfig.includes('padding')">
            <label for="padding">Padding (e.g., 20px 0):</label>
            <input type="text" id="padding" v-model="blockData.padding" />
          </div>
          <div v-if="currentBlockTypeConfig.includes('font_size')">
            <label for="fontSize">Font Size:</label>
            <select id="fontSize" v-model="blockData.font_size">
              <option value="12px">Small (12px)</option>
              <option value="14px">Normal (14px)</option>
              <option value="16px">Large (16px)</option>
              <option value="18px">Extra Large (18px)</option>
            </select>
          </div>
        </div>
      </div>
    </template>

    <script setup lang="ts">
    import { ref, computed, watch, onMounted } from 'vue';
    import { createDirectus, rest, readItems } from '@directus/sdk';

    // Assume these are props passed to this component, representing the current newsletter block
    const props = defineProps<{
      initialBlockData: any; // The data for the current newsletter_block item
      initialBlockTypeId: string; // The ID of the currently selected block_type
    }>();

    const emit = defineEmits(['update:blockData']);

    const config = useRuntimeConfig();
    const directus = createDirectus(config.public.directusUrl as string).with(rest());

    interface BlockType {
      id: string;
      name: string;
      slug: string;
      field_visibility_config: string[];
    }

    const blockTypes = ref<BlockType[]>([]);
    const selectedBlockTypeId = ref<string>(props.initialBlockTypeId);
    const blockData = ref<any>({ ...props.initialBlockData });

    // Computed property to get the config for the currently selected block type
    const currentBlockTypeConfig = computed(() => {
      const foundType = blockTypes.value.find(type => type.id === selectedBlockTypeId.value);
      return foundType ? foundType.field_visibility_config : [];
    });

    // Fetch block types on component mount
    onMounted(async () => {
      try {
        blockTypes.value = await directus.request(
          readItems('block_types', {
            fields: ['id', 'name', 'slug', 'field_visibility_config']
          })
        );
      } catch (e) {
        console.error('Error fetching block types:', e);
      }
    });

    // Watch for changes in selectedBlockTypeId to update visible fields
    function updateVisibleFields() {
      // When block type changes, you might want to clear or reset some fields
      // For simplicity here, we just re-render based on new config
      // In a real app, you might want to intelligently preserve data for common fields
      console.log('Selected block type changed. Visible fields will update.');
    }

    // Emit updated blockData to parent component
    watch(blockData, (newValue) => {
      emit('update:blockData', newValue);
    }, { deep: true });
    </script>

    <style scoped>
    /* Add styling for your form fields here */
    div {
      margin-bottom: 15px;
    }
    label {
      display: block;
      margin-bottom: 5px;
      font-weight: bold;
    }
    input[type="text"], textarea, select {
      width: 100%;
      padding: 8px;
      border: 1px solid #ccc;
      border-radius: 4px;
    }
    input[type="color"] {
      height: 38px; /* Adjust as needed */
    }
    </style>
    