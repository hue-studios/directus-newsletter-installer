#!/bin/bash

# Complete Modular Newsletter Deployment System v5.0
# Full implementation with enhanced UX and proper relationships

set -e

# Configuration
VERSION="5.0.0"
DEPLOYMENT_DIR="${NEWSLETTER_DEPLOY_DIR:-/opt/newsletter-feature}"
SCRIPTS_DIR="$DEPLOYMENT_DIR/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_banner() {
    echo ""
    echo "=================================================================="
    echo "   📦 Complete Modular Newsletter System v${VERSION}"
    echo "=================================================================="
    echo ""
    echo "🆕 Enhanced Features:"
    echo "   • Newsletter Templates Collection"
    echo "   • Content Library for reusable blocks"
    echo "   • Enhanced subscriber management"
    echo "   • Newsletter categories, tags, and scheduling"
    echo "   • A/B testing and approval workflow"
    echo "   • Advanced analytics and performance tracking"
    echo "   • Proper blocks relationship with perfect UX"
    echo ""
    echo "🔧 Modular Structure:"
    echo "   • Separate scripts for each component"
    echo "   • Easy debugging and maintenance"
    echo "   • Individual component testing"
    echo "   • Better error isolation"
    echo ""
    echo "=================================================================="
    echo ""
}

setup_environment() {
    print_status "🔧 Setting up complete modular environment..."
    
    # Create directory structure
    mkdir -p "$DEPLOYMENT_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$DEPLOYMENT_DIR/installers"
    mkdir -p "$DEPLOYMENT_DIR/frontend-integration"
    
    cd "$DEPLOYMENT_DIR"
    
    # Create all components
    create_package_json
    create_common_functions
    create_install_collections_script    # ADD THIS LINE
    create_install_frontend_script       # ADD THIS LINE
    create_complete_installer
    create_frontend_integration
    create_flow_installer
    create_debug_tools
    
    # Make all scripts executable
    chmod +x scripts/*.sh
    chmod +x installers/*.js
    
    print_success "✅ Complete modular environment setup completed!"
    show_structure
}

create_package_json() {
    print_status "📝 Creating package.json with all dependencies..."
    
    cat > package.json << 'EOF'
{
  "name": "newsletter-modular-deployment",
  "version": "5.0.0",
  "type": "module",
  "description": "Complete Modular Newsletter System for Directus 11 with Enhanced UX",
  "scripts": {
    "setup": "./scripts/setup-environment.sh",
    "install-collections": "./scripts/install-collections.sh", 
    "install-frontend": "./scripts/install-frontend.sh",
    "install-flow": "./scripts/install-flow.sh",
    "debug": "./scripts/debug-installation.sh",
    "fix-flow": "node installers/fix-flow-connections.js"
  },
  "dependencies": {
    "@directus/sdk": "^17.0.0",
    "mjml": "^4.14.1",
    "handlebars": "^4.7.8",
    "@sendgrid/mail": "^8.1.3"
  },
  "devDependencies": {
    "@types/mjml": "^4.7.4",
    "@types/node": "^20.0.0"
  },
  "keywords": [
    "directus", "newsletter", "mjml", "email", "templates", 
    "content-library", "subscribers", "flows", "automation", "ux"
  ],
  "author": "Your Agency",
  "license": "MIT"
}
EOF
    
    print_success "✅ Package.json created with all dependencies"
}

create_common_functions() {
    print_status "📝 Creating common functions..."
    
    cat > scripts/common.sh << 'EOF'
#!/bin/bash
# scripts/common.sh - Shared functions and utilities

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_node() {
    if ! command_exists node; then
        print_error "Node.js is required but not installed"
        print_status "Install Node.js 16+ and try again"
        return 1
    fi
    
    NODE_VERSION=$(node --version | cut -d. -f1 | cut -dv -f2)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_error "Node.js 16+ required, found: $(node --version)"
        return 1
    fi
    
    print_success "✅ Node.js $(node --version) detected"
    return 0
}

install_dependencies() {
    local deployment_dir="${NEWSLETTER_DEPLOY_DIR:-/opt/newsletter-feature}"
    
    print_status "📦 Installing Node.js dependencies..."
    
    # Save current directory
    local current_dir=$(pwd)
    
    # Check if package.json exists
    if [ ! -f "$deployment_dir/package.json" ]; then
        print_error "❌ package.json not found in $deployment_dir"
        print_status "   Run './deploy.sh setup' first to create the modular environment"
        return 1
    fi
    
    # Navigate to deployment directory
    cd "$deployment_dir"
    
    # Check if dependencies are already installed and working
    if [ -d "node_modules" ] && [ -d "node_modules/@directus" ] && [ -d "node_modules/mjml" ]; then
        print_success "✅ Dependencies already installed"
        cd "$current_dir"
        return 0
    fi
    
    print_status "   Installing npm packages..."
    
    # Install dependencies with error handling
    if npm install --no-audit --no-fund; then
        print_success "✅ Dependencies installed successfully"
        
        # Verify critical dependencies are installed
        local missing_deps=()
        for dep in "@directus/sdk" "mjml" "handlebars" "@sendgrid/mail"; do
            if [ ! -d "node_modules/$dep" ]; then
                missing_deps+=("$dep")
            fi
        done
        
        if [ ${#missing_deps[@]} -gt 0 ]; then
            print_error "❌ Missing critical dependencies: ${missing_deps[*]}"
            cd "$current_dir"
            return 1
        fi
        
        print_success "✅ All critical dependencies verified"
    else
        print_error "❌ Failed to install dependencies"
        print_status ""
        print_status "💡 Try manual installation:"
        print_status "   cd $deployment_dir"
        print_status "   rm -rf node_modules package-lock.json"
        print_status "   npm install"
        cd "$current_dir"
        return 1
    fi
    
    # Return to original directory
    cd "$current_dir"
    return 0
}

validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        print_error "Invalid URL format: $url"
        return 1
    fi
    return 0
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        print_error "Invalid email format: $email"
        return 1
    fi
    return 0
}

test_directus_connection() {
    local url="$1"
    print_status "🔍 Testing Directus connection..."
    
    if curl -sf "$url/server/health" >/dev/null 2>&1; then
        print_success "✅ Directus is accessible"
        return 0
    else
        print_error "❌ Cannot connect to Directus at $url"
        return 1
    fi
}
EOF

    print_success "✅ Common functions created"
}

# Add these two functions to your deploy.sh script (after create_common_functions)

create_install_collections_script() {
    print_status "📝 Creating collections installer script..."
    
    cat > scripts/install-collections.sh << 'EOF'
#!/bin/bash
# scripts/install-collections.sh - Install Newsletter Collections

set -e
source "$(dirname "$0")/common.sh"

DIRECTUS_URL="$1"
EMAIL="$2" 
PASSWORD="$3"
FRONTEND_URL="$4"
WEBHOOK_SECRET="${5:-newsletter-webhook-$(date +%s)}"

if [ -z "$DIRECTUS_URL" ] || [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    print_error "Usage: $0 <directus-url> <email> <password> [frontend-url] [webhook-secret]"
    exit 1
fi

# Validate inputs
validate_url "$DIRECTUS_URL" || exit 1
validate_email "$EMAIL" || exit 1
test_directus_connection "$DIRECTUS_URL" || exit 1

print_status "📦 Installing enhanced newsletter collections..."
print_status "   Directus: $DIRECTUS_URL"
print_status "   Frontend: ${FRONTEND_URL:-'Not provided'}"

# Check dependencies
check_node || exit 1
install_dependencies

# Run the enhanced newsletter installer
cd "$DEPLOYMENT_DIR"
node installers/newsletter-installer.js "$DIRECTUS_URL" "$EMAIL" "$PASSWORD" "$FRONTEND_URL" "$WEBHOOK_SECRET"

print_success "✅ Enhanced collections installation completed"
EOF

    chmod +x scripts/install-collections.sh
    print_success "✅ Collections installer script created"
}

create_install_frontend_script() {
    print_status "📝 Creating frontend installer script..."
    
    cat > scripts/install-frontend.sh << 'EOF'
#!/bin/bash
# scripts/install-frontend.sh - Install Frontend Integration

set -e
source "$(dirname "$0")/common.sh"

# Set deployment directory
DEPLOYMENT_DIR="${NEWSLETTER_DEPLOY_DIR:-/opt/newsletter-feature}"

NUXT_PROJECT_PATH="$1"

print_status "🎨 Installing frontend integration..."

if [ -z "$NUXT_PROJECT_PATH" ]; then
    print_warning "No Nuxt project path provided"
    print_status "Frontend integration package is available in:"
    print_status "   $(pwd)/../frontend-integration/"
    print_status ""
    print_status "To install manually:"
    print_status "   cp -r $(pwd)/../frontend-integration/* /path/to/your/nuxt/project/"
    exit 0
fi

if [ ! -d "$NUXT_PROJECT_PATH" ]; then
    print_error "Nuxt project path not found: $NUXT_PROJECT_PATH"
    exit 1
fi

print_status "Installing to: $NUXT_PROJECT_PATH"

# Copy frontend integration files
print_status "📁 Copying server endpoints..."
cp -r ../frontend-integration/server/ "$NUXT_PROJECT_PATH/server/" 2>/dev/null || {
    mkdir -p "$NUXT_PROJECT_PATH/server"
    cp -r ../frontend-integration/server/* "$NUXT_PROJECT_PATH/server/"
}

print_status "📁 Copying TypeScript types..."
cp -r ../frontend-integration/types/ "$NUXT_PROJECT_PATH/types/" 2>/dev/null || {
    mkdir -p "$NUXT_PROJECT_PATH/types"
    cp -r ../frontend-integration/types/* "$NUXT_PROJECT_PATH/types/"
}

print_status "📁 Copying Vue.js components..."
cp -r ../frontend-integration/components/ "$NUXT_PROJECT_PATH/components/" 2>/dev/null || {
    mkdir -p "$NUXT_PROJECT_PATH/components"
    cp -r ../frontend-integration/components/* "$NUXT_PROJECT_PATH/components/"
}

print_status "📁 Copying composables..."
cp -r ../frontend-integration/composables/ "$NUXT_PROJECT_PATH/composables/" 2>/dev/null || {
    mkdir -p "$NUXT_PROJECT_PATH/composables"
    cp -r ../frontend-integration/composables/* "$NUXT_PROJECT_PATH/composables/"
}

print_success "✅ Frontend integration installed successfully!"
print_status ""
print_status "📋 Next steps:"
print_status "1. Install dependencies: npm install mjml @sendgrid/mail handlebars @directus/sdk"
print_status "2. Update your nuxt.config.ts with runtime configuration"
print_status "3. Set up environment variables in .env"
print_status "4. See frontend-integration/README.md for detailed setup"
EOF

    chmod +x scripts/install-frontend.sh
    print_success "✅ Frontend installer script created"
}

create_complete_installer() {
    print_status "📝 Creating complete enhanced newsletter installer..."
    
    cat > installers/newsletter-installer.js << 'EOF'
#!/usr/bin/env node

/**
 * Complete Enhanced Newsletter Feature Installer v5.0
 * Includes proper blocks relationship and enhanced UX
 */

import { createDirectus, rest, authentication, readCollections, createCollection, createField, createRelation, createItems, createFlow, createOperation, updateItem } from '@directus/sdk';

class CompleteNewsletterInstaller {
  constructor(directusUrl, email, password, options = {}) {
    this.directus = createDirectus(directusUrl).with(rest()).with(authentication());
    this.email = email;
    this.password = password;
    this.existingCollections = new Set();
    this.options = {
      createFlow: options.createFlow !== false,
      frontendUrl: options.frontendUrl || null,
      webhookSecret: options.webhookSecret || 'newsletter-webhook-' + Date.now()
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
    console.log('\n📦 Creating enhanced newsletter collections...');

    const collections = [
      // Newsletter Templates
      {
        collection: 'newsletter_templates',
        meta: {
          accountability: 'all',
          collection: 'newsletter_templates',
          hidden: false,
          icon: 'article',
          note: 'Reusable newsletter templates with pre-configured blocks',
          display_template: '{{name}} ({{category}})',
          sort: 1,
          singleton: false,
          translations: null,
          archive_field: null,
          archive_value: null,
          unarchive_value: null,
          archive_app_filter: true,
          sort_field: null
        },
        schema: { name: 'newsletter_templates' }
      },

      // Content Library
      {
        collection: 'content_library',
        meta: {
          accountability: 'all',
          collection: 'content_library',
          hidden: false,
          icon: 'inventory_2',
          note: 'Reusable content blocks and snippets',
          display_template: '{{title}} ({{content_type}})',
          sort: 2
        },
        schema: { name: 'content_library' }
      },

      // Enhanced Subscribers
      {
        collection: 'subscribers',
        meta: {
          accountability: 'all',
          collection: 'subscribers',
          hidden: false,
          icon: 'person',
          note: 'Newsletter subscribers with enhanced management',
          display_template: '{{name}} ({{email}}) - {{status}}',
          sort: 3
        },
        schema: { name: 'subscribers' }
      },

      // Enhanced Mailing Lists
      {
        collection: 'mailing_lists',
        meta: {
          accountability: 'all',
          collection: 'mailing_lists',
          hidden: false,
          icon: 'group',
          note: 'Subscriber mailing lists with segmentation',
          display_template: '{{name}} ({{subscriber_count}} subscribers)',
          sort: 4
        },
        schema: { name: 'mailing_lists' }
      },

      // Junction table for M2M relationship
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

      // Enhanced Newsletters (main collection)
      {
        collection: 'newsletters',
        meta: {
          accountability: 'all',
          collection: 'newsletters',
          hidden: false,
          icon: 'mail',
          note: 'Email newsletters with enhanced features and blocks',
          display_template: '{{title}} - {{status}} ({{category}})',
          sort: 5
        },
        schema: { name: 'newsletters' }
      },

      // Newsletter Blocks (critical for content)
      {
        collection: 'newsletter_blocks',
        meta: {
          accountability: 'all',
          collection: 'newsletter_blocks',
          hidden: false,
          icon: 'view_module',
          note: 'Individual MJML blocks for newsletters',
          display_template: '{{block_type.name}} (#{{sort}})',
          sort: 6
        },
        schema: { name: 'newsletter_blocks' }
      },

      // Block Types (templates for blocks)
      {
        collection: 'block_types',
        meta: {
          accountability: 'all',
          collection: 'block_types',
          hidden: false,
          icon: 'extension',
          note: 'Available MJML block types for newsletters',
          display_template: '{{name}}',
          sort: 7
        },
        schema: { name: 'block_types' }
      },

      // Enhanced Newsletter Sends (tracking)
      {
        collection: 'newsletter_sends',
        meta: {
          accountability: 'all',
          collection: 'newsletter_sends',
          hidden: false,
          icon: 'send',
          note: 'Track newsletter send history and analytics',
          display_template: '{{newsletter.title}} to {{mailing_list.name}} - {{status}}',
          sort: 8
        },
        schema: { name: 'newsletter_sends' }
      }
    ];

    for (const collection of collections) {
      await this.createCollectionSafely(collection);
    }

    console.log('\n🔧 Adding enhanced fields to collections...');
    
    await this.addNewsletterTemplateFields();
    await this.addContentLibraryFields();
    await this.addEnhancedSubscriberFields();
    await this.addEnhancedMailingListFields();
    await this.addJunctionFields();
    await this.addEnhancedNewsletterFields(); // Includes blocks relationship!
    await this.addNewsletterBlockFields();
    await this.addBlockTypeFields();
    await this.addEnhancedNewsletterSendFields();
  }

  async addNewsletterTemplateFields() {
    console.log('\n📝 Adding fields to newsletter_templates...');
    
    const fields = [
      {
        field: 'name',
        type: 'string',
        meta: { 
          interface: 'input', 
          required: true, 
          width: 'half',
          note: 'Template name (e.g., "Weekly Update Template")'
        },
        schema: { is_nullable: false }
      },
      {
        field: 'description',
        type: 'text',
        meta: { 
          interface: 'input-multiline', 
          width: 'half',
          note: 'Brief description of when to use this template'
        }
      },
      {
        field: 'category',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Company News', value: 'company' },
              { text: 'Product Updates', value: 'product' },
              { text: 'Weekly Digest', value: 'weekly' },
              { text: 'Monthly Report', value: 'monthly' },
              { text: 'Event Announcement', value: 'event' },
              { text: 'Special Offer', value: 'offer' },
              { text: 'Customer Story', value: 'story' },
              { text: 'Other', value: 'other' }
            ]
          },
          default_value: 'company'
        }
      },
      {
        field: 'thumbnail_url',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'half',
          note: 'Preview image URL for template selection'
        }
      },
      {
        field: 'blocks_config',
        type: 'json',
        meta: {
          interface: 'input-code',
          options: { language: 'json' },
          note: 'Saved block configuration for this template'
        }
      },
      {
        field: 'default_subject_pattern',
        type: 'string',
        meta: { 
          interface: 'input',
          note: 'Default subject pattern (e.g., "Weekly Update - {{date}}")',
          options: { placeholder: 'Weekly Update - {{date}}' }
        }
      },
      {
        field: 'default_from_name',
        type: 'string',
        meta: { 
          interface: 'input',
          width: 'half',
          note: 'Default sender name for this template'
        }
      },
      {
        field: 'default_from_email',
        type: 'string',
        meta: { 
          interface: 'input',
          width: 'half',
          note: 'Default sender email for this template'
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
              { text: 'Published', value: 'published' },
              { text: 'Draft', value: 'draft' }
            ]
          },
          default_value: 'published'
        }
      },
      {
        field: 'usage_count',
        type: 'integer',
        meta: { 
          interface: 'input', 
          readonly: true, 
          width: 'half',
          note: 'How many times this template has been used'
        },
        schema: { default_value: 0 }
      },
      {
        field: 'tags',
        type: 'csv',
        meta: { 
          interface: 'tags',
          note: 'Tags for easier template discovery'
        }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('newsletter_templates', field);
    }
  }

  async addContentLibraryFields() {
    console.log('\n📝 Adding fields to content_library...');
    
    const fields = [
      {
        field: 'title',
        type: 'string',
        meta: { 
          interface: 'input', 
          required: true, 
          width: 'half',
          note: 'Content block title'
        },
        schema: { is_nullable: false }
      },
      {
        field: 'content_type',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Text Block', value: 'text' },
              { text: 'Hero Section', value: 'hero' },
              { text: 'Button', value: 'button' },
              { text: 'Image Block', value: 'image' },
              { text: 'Custom HTML', value: 'html' },
              { text: 'Social Media', value: 'social' },
              { text: 'Footer', value: 'footer' }
            ]
          }
        }
      },
      {
        field: 'content_data',
        type: 'json',
        meta: {
          interface: 'input-code',
          options: { language: 'json' },
          note: 'Reusable content configuration'
        }
      },
      {
        field: 'preview_text',
        type: 'text',
        meta: {
          interface: 'input-multiline',
          note: 'Short preview of content for selection'
        }
      },
      {
        field: 'tags',
        type: 'csv',
        meta: { 
          interface: 'tags',
          note: 'Tags for content organization'
        }
      },
      {
        field: 'category',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          options: {
            choices: [
              { text: 'Headers', value: 'headers' },
              { text: 'Footers', value: 'footers' },
              { text: 'Call to Actions', value: 'cta' },
              { text: 'Product Features', value: 'features' },
              { text: 'Social Media', value: 'social' },
              { text: 'Legal', value: 'legal' }
            ]
          }
        }
      },
      {
        field: 'usage_count',
        type: 'integer',
        meta: { 
          interface: 'input', 
          readonly: true,
          note: 'Times this content has been used'
        },
        schema: { default_value: 0 }
      },
      {
        field: 'is_global',
        type: 'boolean',
        meta: {
          interface: 'boolean',
          note: 'Available to all users vs. creator only'
        },
        schema: { default_value: true }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('content_library', field);
    }
  }

  async addEnhancedSubscriberFields() {
    console.log('\n📝 Adding enhanced fields to subscribers...');
    
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
        field: 'first_name',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'half',
          note: 'First name (for personalization)'
        }
      },
      {
        field: 'last_name',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'half',
          note: 'Last name (for personalization)'
        }
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
        field: 'job_title',
        type: 'string',
        meta: { 
          interface: 'input', 
          width: 'half',
          note: 'Job title (for segmentation)'
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
              { text: 'Bounced', value: 'bounced' },
              { text: 'Pending Confirmation', value: 'pending' },
              { text: 'Suppressed', value: 'suppressed' }
            ]
          },
          default_value: 'active'
        }
      },
      {
        field: 'subscription_source',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Website Signup', value: 'website' },
              { text: 'Manual Import', value: 'import' },
              { text: 'Manual Entry', value: 'manual' },
              { text: 'Event Registration', value: 'event' },
              { text: 'API Integration', value: 'api' },
              { text: 'Referral', value: 'referral' }
            ]
          }
        }
      },
      {
        field: 'subscription_preferences',
        type: 'json',
        meta: {
          interface: 'select-multiple-checkbox',
          options: {
            choices: [
              { text: 'Company News', value: 'company' },
              { text: 'Product Updates', value: 'product' },
              { text: 'Weekly Digest', value: 'weekly' },
              { text: 'Special Offers', value: 'offers' },
              { text: 'Event Announcements', value: 'events' },
              { text: 'Technical Updates', value: 'technical' }
            ]
          },
          note: 'Which newsletter types they want to receive'
        }
      },
      {
        field: 'custom_fields',
        type: 'json',
        meta: {
          interface: 'input-code',
          options: { language: 'json' },
          note: 'Additional custom fields for personalization'
        }
      },
      {
        field: 'engagement_score',
        type: 'integer',
        meta: { 
          interface: 'slider',
          readonly: true,
          options: { min: 0, max: 100 },
          note: 'Engagement score (0-100)'
        },
        schema: { default_value: 50 }
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
        field: 'last_email_opened',
        type: 'timestamp',
        meta: { 
          interface: 'datetime', 
          readonly: true, 
          width: 'half',
          note: 'Last time they opened an email'
        }
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

  async addEnhancedMailingListFields() {
    console.log('\n📝 Adding enhanced fields to mailing_lists...');
    
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
        field: 'category',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'General', value: 'general' },
              { text: 'Product Updates', value: 'product' },
              { text: 'VIP Customers', value: 'vip' },
              { text: 'Prospects', value: 'prospects' },
              { text: 'Event Attendees', value: 'events' }
            ]
          },
          default_value: 'general'
        }
      },
      {
        field: 'tags',
        type: 'csv',
        meta: { 
          interface: 'tags',
          width: 'half',
          note: 'Tags for list organization'
        }
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
        field: 'active_subscriber_count',
        type: 'integer',
        meta: { 
          interface: 'input', 
          readonly: true, 
          width: 'half',
          note: 'Active subscribers only'
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
              { text: 'Inactive', value: 'inactive' },
              { text: 'Archived', value: 'archived' }
            ]
          },
          default_value: 'active'
        }
      },
      {
        field: 'double_opt_in',
        type: 'boolean',
        meta: {
          interface: 'boolean',
          width: 'half',
          note: 'Require email confirmation for new subscribers'
        },
        schema: { default_value: false }
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
      },
      {
        field: 'subscribed_at',
        type: 'timestamp',
        meta: { 
          interface: 'datetime', 
          readonly: true,
          note: 'When they joined this specific list'
        },
        schema: { default_value: 'now()' }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('mailing_lists_subscribers', field);
    }
  }

  async addEnhancedNewsletterFields() {
    console.log('\n📝 Adding enhanced fields to newsletters (INCLUDING BLOCKS RELATIONSHIP)...');
    
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
          note: 'URL-friendly slug for public preview',
          options: { iconLeft: 'link' }
        },
        schema: { is_nullable: false, is_unique: true, has_index: true } 
      },
      
      // *** CRITICAL: BLOCKS RELATIONSHIP FIELD ***
      {
        field: 'blocks',
        type: 'alias',
        meta: {
          interface: 'list-o2m',
          special: ['o2m'],
          options: {
            template: '{{block_type.name}} (#{{sort}})',
            enableCreate: true,
            enableSelect: true
          },
          note: 'Newsletter content blocks - drag to reorder, click + to add new blocks',
          width: 'full'
        }
      },
      
      {
        field: 'category',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Company News', value: 'company' },
              { text: 'Product Updates', value: 'product' },
              { text: 'Weekly Digest', value: 'weekly' },
              { text: 'Monthly Report', value: 'monthly' },
              { text: 'Event Announcement', value: 'event' },
              { text: 'Special Offer', value: 'offer' },
              { text: 'Customer Story', value: 'story' }
            ]
          },
          default_value: 'company'
        }
      },
      {
        field: 'tags',
        type: 'csv',
        meta: { 
          interface: 'tags',
          width: 'half',
          note: 'Tags for newsletter organization'
        }
      },
      {
        field: 'template_id',
        type: 'integer',
        meta: {
          interface: 'select-dropdown-m2o',
          width: 'half',
          note: 'Newsletter template used (optional)',
          display_options: { template: '{{name}}' }
        }
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
          width: 'half',
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
              { text: 'Scheduled', value: 'scheduled' },
              { text: 'Sending', value: 'sending' },
              { text: 'Sent', value: 'sent' },
              { text: 'Paused', value: 'paused' }
            ]
          },
          default_value: 'draft'
        }
      },
      {
        field: 'priority',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Low', value: 'low' },
              { text: 'Normal', value: 'normal' },
              { text: 'High', value: 'high' },
              { text: 'Urgent', value: 'urgent' }
            ]
          },
          default_value: 'normal'
        }
      },
      {
        field: 'scheduled_send_date',
        type: 'timestamp',
        meta: {
          interface: 'datetime',
          width: 'half',
          note: 'When to automatically send this newsletter'
        }
      },
      {
        field: 'is_ab_test',
        type: 'boolean',
        meta: {
          interface: 'boolean',
          width: 'half',
          note: 'Enable A/B testing for this newsletter'
        },
        schema: { default_value: false }
      },
      {
        field: 'ab_test_percentage',
        type: 'integer',
        meta: {
          interface: 'slider',
          width: 'half',
          note: 'Percentage of audience for A/B test (5-50%)',
          options: { min: 5, max: 50, step: 5 }
        },
        schema: { default_value: 10 }
      },
      {
        field: 'ab_test_subject_b',
        type: 'string',
        meta: {
          interface: 'input',
          note: 'Alternative subject line for A/B test'
        }
      },
      {
        field: 'open_rate',
        type: 'decimal',
        meta: { 
          interface: 'input', 
          readonly: true, 
          width: 'third',
          note: 'Open rate percentage'
        }
      },
      {
        field: 'click_rate',
        type: 'decimal',
        meta: { 
          interface: 'input', 
          readonly: true, 
          width: 'third',
          note: 'Click-through rate percentage'
        }
      },
      {
        field: 'total_opens',
        type: 'integer',
        meta: { 
          interface: 'input', 
          readonly: true, 
          width: 'third',
          note: 'Total number of opens'
        },
        schema: { default_value: 0 }
      },
      {
        field: 'approval_status',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Pending Review', value: 'pending' },
              { text: 'Approved', value: 'approved' },
              { text: 'Rejected', value: 'rejected' },
              { text: 'Changes Requested', value: 'changes_requested' }
            ]
          },
          default_value: 'pending'
        }
      },
      {
        field: 'approval_notes',
        type: 'text',
        meta: {
          interface: 'input-multiline',
          note: 'Notes from reviewer'
        }
      },
      {
        field: 'mailing_list_id',
        type: 'integer',
        meta: {
          interface: 'select-dropdown-m2o',
          width: 'half',
          note: 'Which mailing list to send to',
          display_options: { template: '{{name}}' }
        }
      },
      {
        field: 'test_emails',
        type: 'csv',
        meta: {
          interface: 'tags',
          note: 'Email addresses for test sends'
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
      },
      {
        field: 'icon',
        type: 'string',
        meta: {
          interface: 'select-icon',
          width: 'half',
          note: 'Icon for block type in admin'
        }
      },
      {
        field: 'category',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Content', value: 'content' },
              { text: 'Layout', value: 'layout' },
              { text: 'Media', value: 'media' },
              { text: 'Interactive', value: 'interactive' }
            ]
          },
          default_value: 'content'
        }
      }
    ];

    for (const field of fields) {
      await this.createFieldWithRetry('block_types', field);
    }
  }

  async addEnhancedNewsletterSendFields() {
    console.log('\n📝 Adding enhanced fields to newsletter_sends...');
    
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
              { text: 'Failed', value: 'failed' },
              { text: 'Paused', value: 'paused' }
            ]
          },
          default_value: 'pending'
        }
      },
      {
        field: 'send_type',
        type: 'string',
        meta: {
          interface: 'select-dropdown',
          width: 'half',
          options: {
            choices: [
              { text: 'Regular Send', value: 'regular' },
              { text: 'Test Send', value: 'test' },
              { text: 'A/B Test A', value: 'ab_test_a' },
              { text: 'A/B Test B', value: 'ab_test_b' }
            ]
          },
          default_value: 'regular'
        }
      },
      {
        field: 'total_recipients',
        type: 'integer',
        meta: { interface: 'input', readonly: true, width: 'third' }
      },
      {
        field: 'sent_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, width: 'third' },
        schema: { default_value: 0 }
      },
      {
        field: 'failed_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, width: 'third' },
        schema: { default_value: 0 }
      },
      {
        field: 'open_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, width: 'third' },
        schema: { default_value: 0 }
      },
      {
        field: 'click_count',
        type: 'integer',
        meta: { interface: 'input', readonly: true, width: 'third' },
        schema: { default_value: 0 }
      },
      {
        field: 'open_rate',
        type: 'decimal',
        meta: { interface: 'input', readonly: true, width: 'third' }
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
    console.log('\n🔗 Creating enhanced relationships...');

    const relations = [
      // *** CRITICAL: Newsletter → Blocks (O2M) ***
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

      // Newsletter Blocks → Block Types (M2O)
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

      // Newsletter Templates → Newsletters (O2M)
      {
        collection: 'newsletters',
        field: 'template_id',
        related_collection: 'newsletter_templates',
        meta: {
          many_collection: 'newsletters',
          many_field: 'template_id',
          one_collection: 'newsletter_templates',
          one_deselect_action: 'nullify'
        }
      },

      // Newsletter → Mailing List (M2O)
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

      // Mailing Lists ↔ Subscribers (M2M)
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

      // Newsletter Sends → Newsletter (M2O)
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

      // Newsletter Sends → Mailing List (M2O)
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
        console.log(`✅ Created relation: ${relation.collection}.${relation.field} → ${relation.related_collection}`);
        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⏭️  Relation already exists: ${relation.collection}.${relation.field} → ${relation.related_collection}`);
        } else {
          console.error(`❌ Failed to create relation: ${relation.collection}.${relation.field}`, error.message);
        }
      }
    }
  }

  async insertEnhancedSampleData() {
    console.log('\n🧩 Installing enhanced sample data...');

    // Enhanced Block Types with perfect UX
    const blockTypes = [
      {
        name: "Hero Section",
        slug: "hero",
        description: "Large header section with title, subtitle, and optional button",
        category: "content",
        icon: "title",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-text align="{{text_align}}" font-size="32px" font-weight="bold" color="{{text_color}}">
      {{title}}
    </mj-text>
    {{#if subtitle}}
    <mj-text align="{{text_align}}" font-size="18px" color="{{text_color}}" padding="10px 0">
      {{subtitle}}
    </mj-text>
    {{/if}}
    {{#if button_text}}
    <mj-button background-color="#007bff" color="#ffffff" href="{{button_url}}" padding="20px 0">
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
        category: "content",
        icon: "text_fields",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    <mj-text align="{{text_align}}" font-size="{{font_size}}" color="{{text_color}}">
      {{{text_content}}}
    </mj-text>
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["text_content", "background_color", "text_color", "text_align", "padding", "font_size"]
      },
      {
        name: "Image Block",
        slug: "image",
        description: "Image with optional caption and link",
        category: "media",
        icon: "image",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column>
    {{#if button_url}}
    <mj-image src="{{image_url}}" alt="{{image_alt_text}}" align="{{text_align}}" href="{{button_url}}" />
    {{else}}
    <mj-image src="{{image_url}}" alt="{{image_alt_text}}" align="{{text_align}}" />
    {{/if}}
    {{#if image_caption}}
    <mj-text align="{{text_align}}" font-size="12px" color="#666666" padding="10px 0 0 0">
      {{image_caption}}
    </mj-text>
    {{/if}}
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["image_url", "image_alt_text", "image_caption", "button_url", "background_color", "text_align", "padding"]
      },
      {
        name: "Button",
        slug: "button",
        description: "Call-to-action button with customizable styling",
        category: "interactive",
        icon: "smart_button",
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
        name: "Two Column Layout",
        slug: "two-column",
        description: "Side-by-side content layout",
        category: "layout",
        icon: "view_column",
        mjml_template: `<mj-section background-color="{{background_color}}" padding="{{padding}}">
  <mj-column width="50%">
    <mj-text align="{{text_align}}" font-size="{{font_size}}" color="{{text_color}}">
      {{title}}
    </mj-text>
  </mj-column>
  <mj-column width="50%">
    <mj-text align="{{text_align}}" font-size="{{font_size}}" color="{{text_color}}">
      {{subtitle}}
    </mj-text>
  </mj-column>
</mj-section>`,
        status: "published",
        field_visibility_config: ["title", "subtitle", "background_color", "text_color", "text_align", "padding", "font_size"]
      },
      {
        name: "Divider",
        slug: "divider",
        description: "Horizontal line separator",
        category: "layout",
        icon: "horizontal_rule",
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

    // Sample Newsletter Templates
    const templates = [
      {
        name: "Weekly Company Update",
        description: "Standard template for weekly company newsletters",
        category: "weekly",
        default_subject_pattern: "Weekly Update - {{date}}",
        default_from_name: "Company Newsletter",
        blocks_config: {
          blocks: [
            { type: "hero", title: "Weekly Update", subtitle: "{{date}}" },
            { type: "text", content: "This week's highlights..." },
            { type: "divider" }
          ]
        },
        tags: ["weekly", "company", "standard"],
        status: "published"
      },
      {
        name: "Product Launch Announcement",
        description: "Template for announcing new product releases",
        category: "product",
        default_subject_pattern: "Introducing {{product_name}}",
        blocks_config: {
          blocks: [
            { type: "hero", title: "New Product Launch" },
            { type: "image", caption: "Product showcase" },
            { type: "text", content: "We're excited to announce..." },
            { type: "button", text: "Learn More", url: "#" }
          ]
        },
        tags: ["product", "launch", "announcement"],
        status: "published"
      }
    ];

    for (const template of templates) {
      try {
        await this.directus.request(createItems('newsletter_templates', template));
        console.log(`✅ Created template: ${template.name}`);
      } catch (error) {
        console.log(`⚠️  Could not create template ${template.name}:`, error.message);
      }
    }

    // Sample Content Library Items
    const contentItems = [
      {
        title: "Company Header",
        content_type: "hero",
        content_data: {
          title: "{{company_name}}",
          subtitle: "{{newsletter_type}}",
          background_color: "#f8f9fa"
        },
        preview_text: "Standard company header with dynamic company name",
        tags: ["header", "company"],
        category: "headers",
        is_global: true
      },
      {
        title: "Social Media Footer",
        content_type: "html",
        content_data: {
          html: `<div style="text-align: center; padding: 20px;">
            <a href="{{facebook_url}}" style="margin: 0 10px;">Facebook</a> | 
            <a href="{{twitter_url}}" style="margin: 0 10px;">Twitter</a> | 
            <a href="{{linkedin_url}}" style="margin: 0 10px;">LinkedIn</a>
          </div>`
        },
        preview_text: "Social media links footer",
        tags: ["footer", "social"],
        category: "footers",
        is_global: true
      }
    ];

    for (const item of contentItems) {
      try {
        await this.directus.request(createItems('content_library', item));
        console.log(`✅ Created content item: ${item.title}`);
      } catch (error) {
        console.log(`⚠️  Could not create content item ${item.title}:`, error.message);
      }
    }

    // Enhanced Sample Subscribers
    const subscribers = [
      {
        email: "test@example.com",
        name: "Test User",
        first_name: "Test",
        last_name: "User",
        company: "Test Company",
        job_title: "Marketing Manager",
        status: "active",
        subscription_source: "website",
        subscription_preferences: ["company", "product", "weekly"],
        engagement_score: 85
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

    // Enhanced Sample Mailing Lists
    const mailingLists = [
      {
        name: "General Newsletter",
        description: "General company newsletter subscribers",
        category: "general",
        tags: ["general", "company"],
        subscriber_count: 1,
        active_subscriber_count: 1,
        status: "active",
        double_opt_in: false
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

    console.log('✅ Enhanced sample data installed');
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

      await this.createFlowOperations(flow.id);

      console.log('\n🎉 Newsletter flow created successfully!');

    } catch (error) {
      console.log(`⚠️  Could not create flow automatically: ${error.message}`);
    }
  }

  async createFlowOperations(flowId) {
    console.log('\n🔧 Creating flow operations...');

    const operations = [
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
        }
      },
      {
        name: 'Compile MJML',
        key: 'compile_mjml',
        type: 'request',
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
        }
      },
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
            send_type: 'regular'
          })
        }
      },
      {
        name: 'Send Email',
        key: 'send_email',
        type: 'request',
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
        }
      },
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
        }
      }
    ];

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

    // Connect operations
    const connections = [
      { from: 'validate_newsletter', resolve: 'compile_mjml' },
      { from: 'compile_mjml', resolve: 'create_send_record' },
      { from: 'create_send_record', resolve: 'send_email' },
      { from: 'send_email', resolve: 'update_newsletter_status' }
    ];

    for (const connection of connections) {
      if (createdOperations[connection.from] && createdOperations[connection.resolve]) {
        try {
          await this.directus.request(
            updateItem('directus_operations', createdOperations[connection.from].id, {
              resolve: createdOperations[connection.resolve].id
            })
          );
          console.log(`✅ Connected ${connection.from} → ${connection.resolve}`);
        } catch (error) {
          console.log(`⚠️  Could not connect ${connection.from}:`, error.message);
        }
      }
    }
  }

  async run() {
    console.log('🚀 Starting Complete Enhanced Newsletter Feature Installation v5.0\n');
    console.log('🆕 NEW: Newsletter Templates Collection!\n');
    console.log('🆕 NEW: Content Library for reusable blocks!\n');
    console.log('🆕 NEW: Enhanced subscriber management with segmentation!\n');
    console.log('🆕 NEW: Newsletter categories, tags, and scheduling!\n');
    console.log('🆕 NEW: A/B testing and approval workflow support!\n');
    console.log('🆕 NEW: Advanced analytics and performance tracking!\n');
    console.log('✅ FIXED: Proper blocks relationship with perfect UX!\n');

    if (!(await this.initialize())) {
      return false;
    }

    try {
      await this.createCollections();
      await this.createRelations();
      await this.insertEnhancedSampleData();
      await this.createNewsletterFlow();

      console.log('\n🎉 Complete enhanced newsletter feature installation completed!');
      console.log('\n📦 What was installed:');
      console.log('    • 8 Collections with enhanced UX features');
      console.log('    • Newsletter Templates collection for reusability');
      console.log('    • Content Library for reusable content blocks');
      console.log('    • Enhanced subscriber management with preferences');
      console.log('    • Newsletter categories, tags, and priority levels');
      console.log('    • Scheduling and A/B testing capabilities');
      console.log('    • Approval workflow for team collaboration');
      console.log('    • Advanced analytics and performance tracking');
      console.log('    • ✅ PROPER BLOCKS RELATIONSHIP - Newsletters now have working blocks section!');
      
      console.log('\n📋 Next UX enhancement steps:');
      console.log('1. Go to Content → Newsletters → Create New Newsletter');
      console.log('2. You should see a "Blocks" section where you can add content blocks');
      console.log('3. Try adding a Hero Section, Text Block, and Button');
      console.log('4. Use template selection for faster newsletter creation');
      console.log('5. Set up subscriber segmentation and preferences');
      console.log('6. Copy frontend-integration/ files to your Nuxt project');
      console.log('7. Configure SendGrid and test the complete flow');
      
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
    console.log('Complete Enhanced Newsletter Feature Installer v5.0');
    console.log('');
    console.log('✅ FIXED: Proper blocks relationship included!');
    console.log('🆕 NEW: Templates, Content Library, Enhanced Subscribers, Analytics!');
    console.log('');
    console.log('Usage: node newsletter-installer.js <directus-url> <email> <password> [frontend-url] [webhook-secret]');
    console.log('');
    console.log('Examples:');
    console.log('  # Basic installation with enhanced features');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123');
    console.log('');
    console.log('  # Full automation with flow creation');
    console.log('  node newsletter-installer.js https://admin.example.com admin@example.com password123 https://frontend.example.com');
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
    
    chmod +x installers/newsletter-installer.js
    print_success "✅ Complete newsletter installer created"
}

create_frontend_integration() {
    print_status "📝 Creating complete frontend integration package..."
    
    mkdir -p frontend-integration/server/api/newsletter
    mkdir -p frontend-integration/types
    mkdir -p frontend-integration/components/newsletter
    mkdir -p frontend-integration/composables
    
    # Enhanced MJML compilation endpoint
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

    // Fetch newsletter with enhanced fields and proper blocks relationship
    const newsletter = await directus.request(
      readItem("newsletters", newsletter_id, {
        fields: [
          "*",
          "blocks.id",
          "blocks.sort",
          // Individual content fields for enhanced UX
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
          // Block type info with enhanced fields
          "blocks.block_type.name",
          "blocks.block_type.slug",
          "blocks.block_type.mjml_template",
          "blocks.block_type.field_visibility_config",
          "blocks.block_type.category",
          "blocks.block_type.icon",
          // Legacy content field (fallback)
          "blocks.content",
          // Template info if used
          "template_id.name",
          "template_id.category"
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

    // Compile each block with enhanced data structure
    let compiledBlocks = "";

    for (const block of sortedBlocks) {
      if (!block.block_type?.mjml_template) {
        console.warn(`Block ${block.id} has no MJML template`);
        continue;
      }

      try {
        // Enhanced block data preparation using individual fields
        const blockData = {
          // Text content from individual fields (enhanced UX)
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
          
          // Styling fields with enhanced defaults
          background_color: block.background_color || (block.content?.background_color) || '#ffffff',
          text_color: block.text_color || (block.content?.text_color) || '#333333',
          text_align: block.text_align || (block.content?.text_align) || 'center',
          
          // Layout fields
          padding: block.padding || (block.content?.padding) || '20px 0',
          font_size: block.font_size || (block.content?.font_size) || '14px',
          
          // Dynamic personalization variables
          company_name: '{{company_name}}',
          subscriber_name: '{{subscriber_name}}',
          unsubscribe_url: '{{unsubscribe_url}}',
          preferences_url: '{{preferences_url}}'
        };

        // Compile handlebars template with enhanced data
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

    // Enhanced header and footer with better styling
    const headerPartial = `
    <mj-section background-color="#ffffff" padding="20px 0">
      <mj-column>
        <mj-image src="${config.public.siteUrl || config.public.directusUrl}/assets/logo.png" alt="Newsletter" width="200px" align="center" />
      </mj-column>
    </mj-section>`;

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
    </mj-section>`;

    // Build complete MJML with enhanced structure
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
        ${headerPartial}
        ${compiledBlocks}
        ${footerPartial}
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
      message: "MJML compiled successfully with enhanced features",
      warnings: mjmlResult.errors.length > 0 ? mjmlResult.errors : null,
      blocks_compiled: sortedBlocks.length,
      newsletter_category: newsletter.category,
      has_template: !!newsletter.template_id
    };
  } catch (error: any) {
    console.error("Enhanced MJML compilation error:", error);

    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || "Internal server error",
    });
  }
});
EOF

    # Enhanced send endpoint
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

    // Fetch enhanced newsletter and mailing list data
    const sendRecord = await directus.request(
      readItem("newsletter_sends", send_record_id, {
        fields: [
          "*",
          "newsletter.title",
          "newsletter.subject_line",
          "newsletter.from_name",
          "newsletter.from_email",
          "newsletter.compiled_html",
          "newsletter.category",
          "newsletter.priority",
          "newsletter.is_ab_test",
          "newsletter.ab_test_subject_b",
          "mailing_list.name",
          "mailing_list.category",
          "mailing_list.subscribers.subscribers_id.email",
          "mailing_list.subscribers.subscribers_id.name",
          "mailing_list.subscribers.subscribers_id.first_name",
          "mailing_list.subscribers.subscribers_id.status",
          "mailing_list.subscribers.subscribers_id.custom_fields"
        ],
      })
    );

    if (!sendRecord || !sendRecord.newsletter.compiled_html) {
      throw createError({
        statusCode: 400,
        statusMessage: "Send record not found or newsletter HTML not compiled",
      });
    }

    const subscribers = sendRecord.mailing_list?.subscribers?.filter(
      (sub: any) => sub.subscribers_id.status === 'active'
    ) || [];
    
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
        message: "No active subscribers in mailing list",
        sent_count: 0,
      };
    }

    // Enhanced personalization and sending logic
    const fromEmail = sendRecord.newsletter.from_email || "newsletter@example.com";
    const fromName = sendRecord.newsletter.from_name || "Newsletter";
    
    // Handle A/B testing
    const isABTest = sendRecord.newsletter.is_ab_test;
    const subjectLine = isABTest && sendRecord.send_type === 'ab_test_b' 
      ? sendRecord.newsletter.ab_test_subject_b 
      : sendRecord.newsletter.subject_line;

    // Generate unique batch ID for SendGrid
    const batchId = `newsletter_${newsletter_id}_${Date.now()}`;

    // Helper function for unsubscribe tokens
    function generateUnsubscribeToken(email: string): string {
      const crypto = require("node:crypto");
      const data = `${email}:${config.directusWebhookSecret}`;
      return crypto
        .createHash("sha256")
        .update(data)
        .digest("hex")
        .substring(0, 16);
    }

    // Create personalizations with enhanced data
    const personalizations = subscribers.map((subscriber: any) => {
      const sub = subscriber.subscribers_id;
      const unsubscribeUrl = `${config.public.siteUrl}/unsubscribe?email=${encodeURIComponent(sub.email)}&token=${generateUnsubscribeToken(sub.email)}`;
      const preferencesUrl = `${config.public.siteUrl}/email-preferences?email=${encodeURIComponent(sub.email)}&token=${generateUnsubscribeToken(sub.email)}`;

      // Enhanced personalization with custom fields
      let personalizedHtml = sendRecord.newsletter.compiled_html
        .replace(/{{unsubscribe_url}}/g, unsubscribeUrl)
        .replace(/{{preferences_url}}/g, preferencesUrl)
        .replace(/{{subscriber_name}}/g, sub.name || sub.first_name || "Subscriber")
        .replace(/{{subscriber_email}}/g, sub.email)
        .replace(/{{company_name}}/g, sub.custom_fields?.company || "");

      return {
        to: [
          {
            email: sub.email,
            name: sub.name || "",
          },
        ],
      };
    });

    // Prepare enhanced email message
    const msg = {
      from: {
        email: fromEmail,
        name: fromName,
      },
      subject: subjectLine,
      html: sendRecord.newsletter.compiled_html,
      personalizations: personalizations,
      batch_id: batchId,
      tracking_settings: {
        click_tracking: {
          enable: true,
          enable_text: true,
        },
        open_tracking: {
          enable: true,
        },
      },
      categories: [
        sendRecord.newsletter.category || 'newsletter',
        sendRecord.send_type || 'regular'
      ]
    };

    let sentCount = 0;
    let failedCount = 0;

    try {
      // Enhanced batch sending with priority handling
      const batchSize = sendRecord.newsletter.priority === 'urgent' ? 50 : 100;
      const delay = sendRecord.newsletter.priority === 'urgent' ? 500 : 1000;

      const batches = [];
      for (let i = 0; i < personalizations.length; i += batchSize) {
        batches.push(personalizations.slice(i, i + batchSize));
      }

      for (const batch of batches) {
        try {
          const batchMsg = {
            ...msg,
            personalizations: batch,
          };

          await sgMail.send(batchMsg);
          sentCount += batch.length;

          if (batches.length > 1) {
            await new Promise((resolve) => setTimeout(resolve, delay));
          }
        } catch (batchError: any) {
          failedCount += batch.length;
          console.error("SendGrid batch error:", batchError);
        }
      }

      // Update send record with enhanced analytics
      await directus.request(
        updateItem("newsletter_sends", send_record_id, {
          status: failedCount === 0 ? "sent" : sentCount > 0 ? "sent" : "failed",
          sent_count: sentCount,
          failed_count: failedCount,
          total_recipients: subscribers.length,
          sendgrid_batch_id: batchId,
          sent_at: new Date().toISOString(),
          delivery_rate: sentCount > 0 ? (sentCount / subscribers.length) * 100 : 0,
        })
      );

      return {
        success: true,
        message: `Newsletter sent successfully to ${sentCount} subscribers`,
        sent_count: sentCount,
        failed_count: failedCount,
        batch_id: batchId,
        category: sendRecord.newsletter.category,
        is_ab_test: isABTest,
        analytics: {
          delivery_rate: sentCount > 0 ? (sentCount / subscribers.length) * 100 : 0,
          total_recipients: subscribers.length
        }
      };
    } catch (error: any) {
      await directus.request(
        updateItem("newsletter_sends", send_record_id, {
          status: "failed",
          sent_count: sentCount,
          failed_count: subscribers.length - sentCount,
          error_log: error.message,
          sent_at: new Date().toISOString(),
        })
      );
      throw error;
    }
  } catch (error: any) {
    console.error("Enhanced newsletter send error:", error);
    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || "Email sending failed",
    });
  }
});
EOF

    # Enhanced TypeScript types
    cat > frontend-integration/types/newsletter.d.ts << 'EOF'
// Enhanced TypeScript types for newsletter system v5.0

export interface Newsletter {
  id: number;
  title: string;
  slug: string;
  category: 'company' | 'product' | 'weekly' | 'monthly' | 'event' | 'offer' | 'story';
  tags: string[];
  template_id?: number;
  subject_line: string;
  preview_text?: string;
  from_name: string;
  from_email: string;
  reply_to?: string;
  status: 'draft' | 'ready' | 'scheduled' | 'sending' | 'sent' | 'paused';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  scheduled_send_date?: string;
  is_ab_test: boolean;
  ab_test_percentage?: number;
  ab_test_subject_b?: string;
  open_rate?: number;
  click_rate?: number;
  total_opens: number;
  approval_status: 'pending' | 'approved' | 'rejected' | 'changes_requested';
  approval_notes?: string;
  mailing_list_id?: number;
  test_emails: string[];
  compiled_mjml?: string;
  compiled_html?: string;
  blocks?: NewsletterBlock[];
}

export interface NewsletterBlock {
  id: number;
  newsletter_id: number;
  block_type: BlockType;
  sort: number;
  title?: string;
  subtitle?: string;
  text_content?: string;
  image_url?: string;
  image_alt_text?: string;
  image_caption?: string;
  button_text?: string;
  button_url?: string;
  background_color: string;
  text_color: string;
  text_align: 'left' | 'center' | 'right';
  padding: string;
  font_size: string;
  content?: Record<string, any>; // Legacy field
  mjml_output?: string;
}

export interface BlockType {
  id: number;
  name: string;
  slug: string;
  description: string;
  mjml_template: string;
  status: 'published' | 'draft' | 'archived';
  field_visibility_config?: string[];
  icon?: string;
  category: 'content' | 'layout' | 'media' | 'interactive';
}

export interface NewsletterTemplate {
  id: number;
  name: string;
  description: string;
  category: string;
  thumbnail_url?: string;
  blocks_config: Record<string, any>;
  default_subject_pattern?: string;
  default_from_name?: string;
  default_from_email?: string;
  status: 'published' | 'draft';
  usage_count: number;
  tags: string[];
}

export interface ContentLibrary {
  id: number;
  title: string;
  content_type: 'text' | 'hero' | 'button' | 'image' | 'html' | 'social' | 'footer';
  content_data: Record<string, any>;
  preview_text?: string;
  tags: string[];
  category: string;
  usage_count: number;
  is_global: boolean;
}

export interface Subscriber {
  id: number;
  email: string;
  name: string;
  first_name?: string;
  last_name?: string;
  company?: string;
  job_title?: string;
  status: 'active' | 'unsubscribed' | 'bounced' | 'pending' | 'suppressed';
  subscription_source: 'website' | 'import' | 'manual' | 'event' | 'api' | 'referral';
  subscription_preferences: string[];
  custom_fields?: Record<string, any>;
  engagement_score: number;
  subscribed_at: string;
  last_email_opened?: string;
  unsubscribe_token: string;
}

export interface MailingList {
  id: number;
  name: string;
  description?: string;
  category: string;
  tags: string[];
  subscriber_count: number;
  active_subscriber_count: number;
  status: 'active' | 'inactive' | 'archived';
  double_opt_in: boolean;
  subscribers?: Subscriber[];
}

export interface NewsletterSend {
  id: number;
  newsletter_id: number;
  mailing_list_id: number;
  status: 'pending' | 'sending' | 'sent' | 'failed' | 'paused';
  send_type: 'regular' | 'test' | 'ab_test_a' | 'ab_test_b';
  total_recipients: number;
  sent_count: number;
  failed_count: number;
  open_count: number;
  click_count: number;
  open_rate?: number;
  error_log?: string;
  sent_at?: string;
}
EOF

    # Vue.js components for enhanced UX
    cat > frontend-integration/components/newsletter/TemplateBrowser.vue << 'EOF'
<template>
  <div class="template-browser">
    <div class="header mb-6">
      <h2 class="text-2xl font-bold mb-2">Choose Newsletter Template</h2>
      <p class="text-gray-600">Start with a pre-designed template or create from scratch</p>
    </div>

    <!-- Category Filter -->
    <div class="filters mb-6">
      <div class="flex gap-2 flex-wrap">
        <button
          v-for="category in categories"
          :key="category.value"
          @click="selectedCategory = category.value"
          :class="[
            'px-4 py-2 rounded-lg text-sm font-medium transition-colors',
            selectedCategory === category.value
              ? 'bg-blue-100 text-blue-700'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          {{ category.text }}
        </button>
      </div>
    </div>

    <!-- Template Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- Blank Template Option -->
      <div
        @click="selectTemplate(null)"
        class="template-card blank-template border-2 border-dashed border-gray-300 hover:border-blue-400 rounded-lg p-6 cursor-pointer transition-colors"
      >
        <div class="flex flex-col items-center justify-center h-40">
          <div class="w-12 h-12 bg-gray-200 rounded-lg flex items-center justify-center mb-4">
            <svg class="w-6 h-6 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
            </svg>
          </div>
          <h3 class="font-medium text-gray-900">Start from Scratch</h3>
          <p class="text-sm text-gray-500 text-center mt-1">Create a custom newsletter</p>
        </div>
      </div>

      <!-- Template Cards -->
      <div
        v-for="template in filteredTemplates"
        :key="template.id"
        @click="selectTemplate(template)"
        class="template-card border border-gray-200 hover:border-blue-400 hover:shadow-lg rounded-lg overflow-hidden cursor-pointer transition-all"
      >
        <!-- Template Preview -->
        <div class="aspect-video bg-gray-50 flex items-center justify-center relative">
          <img
            v-if="template.thumbnail_url"
            :src="template.thumbnail_url"
            :alt="template.name"
            class="w-full h-full object-cover"
          />
          <div v-else class="text-gray-400">
            <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/>
            </svg>
          </div>
          
          <!-- Category Badge -->
          <div class="absolute top-2 left-2">
            <span class="px-2 py-1 bg-white bg-opacity-90 text-xs font-medium text-gray-700 rounded">
              {{ getCategoryText(template.category) }}
            </span>
          </div>
        </div>

        <!-- Template Info -->
        <div class="p-4">
          <h3 class="font-medium text-gray-900 mb-1">{{ template.name }}</h3>
          <p class="text-sm text-gray-600 mb-3">{{ template.description }}</p>
          
          <!-- Tags -->
          <div class="flex gap-1 flex-wrap mb-3">
            <span
              v-for="tag in template.tags.slice(0, 3)"
              :key="tag"
              class="px-2 py-1 bg-gray-100 text-xs text-gray-600 rounded"
            >
              {{ tag }}
            </span>
          </div>

          <!-- Usage Count -->
          <div class="flex items-center justify-between text-xs text-gray-500">
            <span>Used {{ template.usage_count }} times</span>
            <span>{{ template.status }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="filteredTemplates.length === 0" class="text-center py-12">
      <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
        </svg>
      </div>
      <h3 class="text-lg font-medium text-gray-900 mb-2">No templates found</h3>
      <p class="text-gray-600">Try a different category or create a new template</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { NewsletterTemplate } from '~/types/newsletter'

interface Props {
  templates: NewsletterTemplate[]
}

interface Emits {
  (e: 'select', template: NewsletterTemplate | null): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const selectedCategory = ref<string>('all')

const categories = [
  { text: 'All Templates', value: 'all' },
  { text: 'Company News', value: 'company' },
  { text: 'Product Updates', value: 'product' },
  { text: 'Weekly Digest', value: 'weekly' },
  { text: 'Monthly Report', value: 'monthly' },
  { text: 'Events', value: 'event' },
  { text: 'Offers', value: 'offer' },
  { text: 'Stories', value: 'story' },
]

const filteredTemplates = computed(() => {
  if (selectedCategory.value === 'all') {
    return props.templates.filter(t => t.status === 'published')
  }
  return props.templates.filter(t => 
    t.category === selectedCategory.value && t.status === 'published'
  )
})

const selectTemplate = (template: NewsletterTemplate | null) => {
  emit('select', template)
}

const getCategoryText = (category: string) => {
  return categories.find(c => c.value === category)?.text || category
}
</script>

<style scoped>
.template-card:hover {
  transform: translateY(-1px);
}
</style>
EOF

    # Composable for newsletter management
    cat > frontend-integration/composables/useNewsletter.ts << 'EOF'
import type { Newsletter, NewsletterTemplate, BlockType } from '~/types/newsletter'

export const useNewsletter = () => {
  const { $directus } = useNuxtApp()

  // Fetch newsletter templates
  const fetchTemplates = async (): Promise<NewsletterTemplate[]> => {
    try {
      const response = await $directus.items('newsletter_templates').readByQuery({
        filter: { status: { _eq: 'published' } },
        sort: ['usage_count', '-created_at']
      })
      return response.data || []
    } catch (error) {
      console.error('Error fetching templates:', error)
      return []
    }
  }

  // Fetch block types
  const fetchBlockTypes = async (): Promise<BlockType[]> => {
    try {
      const response = await $directus.items('block_types').readByQuery({
        filter: { status: { _eq: 'published' } },
        sort: ['category', 'name']
      })
      return response.data || []
    } catch (error) {
      console.error('Error fetching block types:', error)
      return []
    }
  }

  // Create newsletter from template
  const createFromTemplate = async (
    template: NewsletterTemplate,
    overrides: Partial<Newsletter> = {}
  ): Promise<Newsletter> => {
    try {
      // Create newsletter
      const newsletter = await $directus.items('newsletters').createOne({
        title: overrides.title || `${template.name} - ${new Date().toLocaleDateString()}`,
        category: template.category,
        subject_line: overrides.subject_line || template.default_subject_pattern?.replace('{{date}}', new Date().toLocaleDateString()),
        from_name: overrides.from_name || template.default_from_name,
        from_email: overrides.from_email || template.default_from_email,
        template_id: template.id,
        status: 'draft',
        ...overrides
      })

      // Create blocks from template config
      if (template.blocks_config?.blocks) {
        for (let i = 0; i < template.blocks_config.blocks.length; i++) {
          const blockConfig = template.blocks_config.blocks[i]
          
          // Find matching block type
          const blockTypes = await fetchBlockTypes()
          const blockType = blockTypes.find(bt => bt.slug === blockConfig.type)
          
          if (blockType) {
            await $directus.items('newsletter_blocks').createOne({
              newsletter_id: newsletter.id,
              block_type: blockType.id,
              sort: i + 1,
              ...blockConfig.content
            })
          }
        }
      }

      // Update template usage count
      await $directus.items('newsletter_templates').updateOne(template.id, {
        usage_count: (template.usage_count || 0) + 1
      })

      return newsletter
    } catch (error) {
      console.error('Error creating newsletter from template:', error)
      throw error
    }
  }

  // Compile MJML
  const compileMJML = async (newsletterId: number): Promise<{ success: boolean; message: string }> => {
    try {
      const response = await $fetch('/api/newsletter/compile-mjml', {
        method: 'POST',
        body: { newsletter_id: newsletterId },
        headers: {
          'Authorization': `Bearer ${useRuntimeConfig().directusWebhookSecret}`
        }
      })
      return response
    } catch (error) {
      console.error('Error compiling MJML:', error)
      throw error
    }
  }

  // Send newsletter
  const sendNewsletter = async (newsletterId: number, sendRecordId: number): Promise<{ success: boolean; message: string }> => {
    try {
      const response = await $fetch('/api/newsletter/send', {
        method: 'POST',
        body: { newsletter_id: newsletterId, send_record_id: sendRecordId },
        headers: {
          'Authorization': `Bearer ${useRuntimeConfig().directusWebhookSecret}`
        }
      })
      return response
    } catch (error) {
      console.error('Error sending newsletter:', error)
      throw error
    }
  }

  return {
    fetchTemplates,
    fetchBlockTypes,
    createFromTemplate,
    compileMJML,
    sendNewsletter
  }
}
EOF

    # Enhanced README for frontend integration
    cat > frontend-integration/README.md << 'EOF'
# Enhanced Newsletter Frontend Integration v5.0

Complete Nuxt.js integration package with enhanced UX features and proper blocks relationship.

## ✅ What's Included

### Server Endpoints
- **Enhanced MJML Compilation** (`/api/newsletter/compile-mjml`) - Supports new field structure and templates
- **Advanced Email Sending** (`/api/newsletter/send`) - Enhanced personalization and A/B testing
- **Full Error Handling** - Comprehensive logging and recovery

### Vue.js Components
- **TemplateBrowser.vue** - Beautiful template selection interface
- **BlockEditor.vue** - Drag-and-drop block editing (coming soon)
- **AnalyticsDashboard.vue** - Performance metrics (coming soon)

### TypeScript Types
- **Complete type definitions** for all collections
- **Enhanced newsletter interfaces** with new fields
- **Type-safe composables** for newsletter management

### Composables
- **useNewsletter()** - Newsletter management utilities
- **useBlockTypes()** - Block type management (coming soon)
- **useAnalytics()** - Performance tracking (coming soon)

## 🚀 Installation

### 1. Copy Files to Your Nuxt Project

```bash
# Copy all integration files
cp -r frontend-integration/* /path/to/your/nuxt/project/
```

### 2. Install Dependencies

```bash
cd /path/to/your/nuxt/project
npm install mjml @sendgrid/mail handlebars @directus/sdk
npm install -D @types/mjml
```

### 3. Configure Nuxt

Update your `nuxt.config.ts`:

```typescript
export default defineNuxtConfig({
  runtimeConfig: {
    // Private (server-side only)
    sendgridApiKey: process.env.SENDGRID_API_KEY,
    directusWebhookSecret: process.env.DIRECTUS_WEBHOOK_SECRET,
    
    // Public (client + server)
    public: {
      directusUrl: process.env.DIRECTUS_URL,
      siteUrl: process.env.NUXT_SITE_URL
    }
  },

  // Transpile Directus SDK
  build: {
    transpile: ['@directus/sdk']
  }
})
```

### 4. Environment Variables

Create/update your `.env`:

```env
# Directus Configuration
DIRECTUS_URL=https://admin.yoursite.com
DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret

# SendGrid Configuration  
SENDGRID_API_KEY=SG.your-sendgrid-api-key

# Site Configuration
NUXT_SITE_URL=https://yoursite.com
```

## 🎨 Usage Examples

### Template Selection Interface

```vue
<template>
  <div>
    <TemplateBrowser
      :templates="templates"
      @select="handleTemplateSelect"
    />
  </div>
</template>

<script setup>
const { fetchTemplates, createFromTemplate } = useNewsletter()
const templates = await fetchTemplates()

const handleTemplateSelect = async (template) => {
  if (template) {
    const newsletter = await createFromTemplate(template, {
      title: 'My New Newsletter',
      subject_line: 'Check out our latest updates!'
    })
    await navigateTo(`/newsletters/${newsletter.id}/edit`)
  } else {
    // Create blank newsletter
    await navigateTo('/newsletters/create')
  }
}
</script>
```

### Newsletter Management

```typescript
// Create newsletter from template
const newsletter = await createFromTemplate(selectedTemplate, {
  title: 'Weekly Update - March 2024',
  subject_line: 'Your weekly dose of company news',
  from_name: 'Company Team',
  from_email: 'news@company.com'
})

// Compile MJML
const result = await compileMJML(newsletter.id)
if (result.success) {
  console.log('Newsletter compiled successfully!')
}

// Send newsletter
const sendResult = await sendNewsletter(newsletter.id, sendRecordId)
console.log(`Sent to ${sendResult.sent_count} subscribers`)
```

### Enhanced Block Management

```typescript
// The enhanced system supports individual fields for better UX:
const block = {
  newsletter_id: 1,
  block_type: 2, // Hero Section
  sort: 1,
  
  // Individual fields for better UX (no more complex JSON)
  title: 'Welcome to Our Newsletter',
  subtitle: 'Your monthly dose of company updates',
  button_text: 'Read More',
  button_url: 'https://example.com',
  background_color: '#f8f9fa',
  text_color: '#333333',
  text_align: 'center',
  padding: '40px 0'
}
```

## 🔧 Enhanced Features

### 1. Template System
- **Visual template browser** with categories and search
- **Usage tracking** - see which templates perform best
- **Pre-configured blocks** - start with professional layouts
- **Custom variables** - dynamic content with Handlebars

### 2. Content Library
- **Reusable content blocks** - headers, footers, CTAs
- **Global vs. personal** content - share across team
- **Category organization** - find content quickly
- **Usage analytics** - track content effectiveness

### 3. Enhanced Subscriber Management
- **Preference management** - let subscribers choose content types
- **Engagement scoring** - identify your best subscribers
- **Custom fields** - store additional subscriber data
- **Segmentation** - target specific subscriber groups

### 4. A/B Testing
- **Subject line testing** - optimize open rates
- **Performance tracking** - see which version performs better
- **Automatic winner selection** - based on open rates
- **Statistical significance** - reliable test results

### 5. Analytics & Reporting
- **Open rates** - track email opens
- **Click rates** - measure engagement
- **Bounce tracking** - identify delivery issues
- **Performance trends** - see improvement over time

## 🎯 API Endpoints

### POST /api/newsletter/compile-mjml
Compiles newsletter blocks into MJML and HTML.

**Request:**
```json
{
  "newsletter_id": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "MJML compiled successfully with enhanced features",
  "blocks_compiled": 3,
  "newsletter_category": "company",
  "has_template": true
}
```

### POST /api/newsletter/send
Sends newsletter to mailing list with enhanced personalization.

**Request:**
```json
{
  "newsletter_id": 1,
  "send_record_id": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "Newsletter sent successfully to 150 subscribers",
  "sent_count": 150,
  "batch_id": "newsletter_1_1234567890",
  "analytics": {
    "delivery_rate": 98.7,
    "total_recipients": 152
  }
}
```

## 🚨 Troubleshooting

### Common Issues

**1. Blocks relationship not working**
- Ensure collections were created with proper relationships
- Check that blocks field exists on newsletters collection
- Verify block_type relationship is properly configured

**2. MJML compilation fails**
- Check that block types have valid MJML templates
- Verify individual block fields are populated
- Ensure Handlebars syntax is correct in templates

**3. Email sending issues**
- Verify SendGrid API key is valid and has send permissions
- Check that frontend URL is accessible from Directus server
- Ensure webhook secret matches between frontend and Directus

### Debug Commands

```bash
# Test MJML compilation
curl -X POST http://localhost:3000/api/newsletter/compile-mjml \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1}'

# Check newsletter structure
curl -H "Authorization: Bearer directus-token" \
  "https://admin.site.com/items/newsletters/1?fields=*,blocks.*,blocks.block_type.*"
```

## 🔄 Migration from Previous Versions

If upgrading from an earlier version:

1. **Backup your data** before running the new installer
2. **Run the enhanced installer** to add new collections and fields
3. **Copy new frontend integration files** 
4. **Update your environment variables** with new config
5. **Test the blocks relationship** in a newsletter

## 📚 Next Steps

After installation:

1. **Create your first template** using the enhanced template system
2. **Build your content library** with reusable blocks
3. **Set up subscriber preferences** for better targeting
4. **Configure A/B testing** for subject line optimization
5. **Implement analytics dashboard** for performance tracking

For advanced usage and customization, see the complete documentation in `/docs/`.

---

**Your enhanced newsletter system is ready!** 🚀

The modular v5.0 system provides:
- ✅ Proper blocks relationship with perfect UX
- ✅ Template system for faster creation
- ✅ Content library for reusable components  
- ✅ Enhanced subscriber management
- ✅ A/B testing and analytics
- ✅ Modular deployment for easy maintenance
EOF

    print_success "✅ Complete frontend integration package created"
}

create_flow_installer() {
    print_status "📝 Creating complete flow installer..."
    
    cat > scripts/install-flow.sh << 'EOF'
#!/bin/bash
# scripts/install-flow.sh - Complete Flow Installation

set -e
source "$(dirname "$0")/common.sh"

DIRECTUS_URL="$1"
EMAIL="$2"
PASSWORD="$3" 
FRONTEND_URL="$4"
WEBHOOK_SECRET="${5:-newsletter-webhook-$(date +%s)}"

if [ -z "$DIRECTUS_URL" ] || [ -z "$EMAIL" ] || [ -z "$PASSWORD" ] || [ -z "$FRONTEND_URL" ]; then
    print_error "Usage: $0 <directus-url> <email> <password> <frontend-url> [webhook-secret]"
    exit 1
fi

# Validate inputs
validate_url "$DIRECTUS_URL" || exit 1
validate_email "$EMAIL" || exit 1
validate_url "$FRONTEND_URL" || exit 1
test_directus_connection "$DIRECTUS_URL" || exit 1

print_status "🔄 Installing complete newsletter automation flow..."
print_status "   Directus: $DIRECTUS_URL"
print_status "   Frontend: $FRONTEND_URL"
print_status "   Webhook Secret: ${WEBHOOK_SECRET:0:10}..."

# Create enhanced flow installer
cat > ../installers/flow-installer.js << 'FLOW_EOF'
#!/usr/bin/env node
import { createDirectus, rest, authentication, createFlow, createOperation, updateItem, readItems } from '@directus/sdk';

class EnhancedFlowInstaller {
  constructor(directusUrl, email, password, frontendUrl, webhookSecret) {
    this.directus = createDirectus(directusUrl).with(rest()).with(authentication());
    this.email = email;
    this.password = password;
    this.frontendUrl = frontendUrl;
    this.webhookSecret = webhookSecret;
  }

  async authenticate() {
    try {
      await this.directus.login(this.email, this.password);
      console.log('✅ Authenticated successfully');
      return true;
    } catch (error) {
      console.error('❌ Authentication failed:', error.message);
      return false;
    }
  }

  async checkExistingFlow() {
    try {
      const flows = await this.directus.request(
        readItems('directus_flows', {
          filter: { name: { _eq: 'Send Newsletter' } }
        })
      );
      
      if (flows.length > 0) {
        console.log('⚠️  Newsletter flow already exists, updating...');
        return flows[0];
      }
      return null;
    } catch (error) {
      console.log('Creating new flow...');
      return null;
    }
  }

  async createEnhancedFlow() {
    console.log('🔄 Creating enhanced newsletter sending flow...');
    
    try {
      const existingFlow = await this.checkExistingFlow();
      
      let flow;
      if (existingFlow) {
        flow = existingFlow;
        console.log(`✅ Using existing flow: ${flow.name} (ID: ${flow.id})`);
      } else {
        flow = await this.directus.request(createFlow({
          name: 'Send Newsletter',
          icon: 'send',
          color: '#00D4AA',
          description: 'Enhanced newsletter sending with MJML compilation and analytics',
          status: 'active',
          trigger: 'manual',
          accountability: 'all',
          options: {
            collections: ['newsletters'],
            location: 'item',
            requireConfirmation: true,
            confirmationDescription: 'This will send the newsletter to the selected mailing list. Continue?'
          }
        }));
        console.log(`✅ Flow created: ${flow.name} (ID: ${flow.id})`);
      }
      
      await this.createEnhancedOperations(flow.id);
      
      return flow.id;
    } catch (error) {
      console.error('❌ Flow creation failed:', error.message);
      throw error;
    }
  }

  async createEnhancedOperations(flowId) {
    console.log('🔧 Creating enhanced flow operations...');
    
    const operations = [
      {
        name: 'Validate Newsletter',
        type: 'condition',
        key: 'validate_newsletter',
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
        }
      },
      {
        name: 'Compile MJML',
        type: 'request',
        key: 'compile_mjml', 
        position_x: 39,
        position_y: 1,
        options: {
          method: 'POST',
          url: `${this.frontendUrl}/api/newsletter/compile-mjml`,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.webhookSecret}`
          },
          body: JSON.stringify({
            newsletter_id: '{{$trigger.body.keys[0]}}'
          })
        }
      },
      {
        name: 'Get Newsletter Data',
        type: 'read',
        key: 'get_newsletter_data',
        position_x: 59,
        position_y: 1,
        options: {
          collection: 'newsletters',
          key: '{{$trigger.body.keys[0]}}',
          query: {
            fields: [
              'id',
              'title',
              'mailing_list_id',
              'category',
              'priority'
            ]
          }
        }
      },
      {
        name: 'Create Send Record',
        type: 'create',
        key: 'create_send_record',
        position_x: 79,
        position_y: 1,
        options: {
          collection: 'newsletter_sends',
          payload: JSON.stringify({
            newsletter_id: '{{$trigger.body.keys[0]}}',
            mailing_list_id: '{{get_newsletter_data.mailing_list_id}}',
            status: 'pending',
            send_type: 'regular'
          })
        }
      },
      {
        name: 'Send Email',
        type: 'request',
        key: 'send_email',
        position_x: 99,
        position_y: 1,
        options: {
          method: 'POST',
          url: `${this.frontendUrl}/api/newsletter/send`,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.webhookSecret}`
          },
          body: JSON.stringify({
            newsletter_id: '{{$trigger.body.keys[0]}}',
            send_record_id: '{{create_send_record.id}}'
          })
        }
      },
      {
        name: 'Update Newsletter Status',
        type: 'update',
        key: 'update_newsletter_status',
        position_x: 119,
        position_y: 1,
        options: {
          collection: 'newsletters',
          key: '{{$trigger.body.keys[0]}}',
          payload: JSON.stringify({
            status: 'sent'
          })
        }
      },
      {
        name: 'Log Success',
        type: 'log',
        key: 'log_success',
        position_x: 139,
        position_y: 1,
        options: {
          level: 'info',
          message: 'Newsletter "{{get_newsletter_data.title}}" sent successfully with enhanced features'
        }
      }
    ];

    // Remove existing operations if updating
    try {
      const existingOps = await this.directus.request(
        readItems('directus_operations', {
          filter: { flow: { _eq: flowId } }
        })
      );
      
      for (const op of existingOps) {
        await this.directus.request(
          this.directus.items('directus_operations').deleteOne(op.id)
        );
      }
      console.log(`🗑️  Removed ${existingOps.length} existing operations`);
    } catch (error) {
      // Ignore if no existing operations
    }

    const createdOps = {};
    
    for (const op of operations) {
      try {
        const created = await this.directus.request(createOperation({
          flow: flowId,
          name: op.name,
          key: op.key,
          type: op.type,
          position_x: op.position_x,
          position_y: op.position_y,
          options: op.options
        }));
        
        createdOps[op.key] = created;
        console.log(`✅ Created operation: ${op.name}`);
        
        // Delay to prevent race conditions
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (error) {
        console.error(`❌ Failed to create operation ${op.name}:`, error.message);
      }
    }

    // Connect operations with enhanced error handling
    await this.connectEnhancedOperations(createdOps);
  }

  async connectEnhancedOperations(operations) {
    console.log('🔗 Connecting enhanced flow operations...');
    
    const connections = [
      { from: 'validate_newsletter', to: 'compile_mjml' },
      { from: 'compile_mjml', to: 'get_newsletter_data' },
      { from: 'get_newsletter_data', to: 'create_send_record' },
      { from: 'create_send_record', to: 'send_email' },
      { from: 'send_email', to: 'update_newsletter_status' },
      { from: 'update_newsletter_status', to: 'log_success' }
    ];

    let successCount = 0;
    let failCount = 0;

    for (const conn of connections) {
      if (operations[conn.from] && operations[conn.to]) {
        try {
          await this.directus.request(
            updateItem('directus_operations', operations[conn.from].id, {
              resolve: operations[conn.to].id
            })
          );
          console.log(`✅ Connected ${conn.from} → ${conn.to}`);
          successCount++;
        } catch (error) {
          console.log(`❌ Failed to connect ${conn.from} → ${conn.to}: ${error.message}`);
          failCount++;
        }
      } else {
        console.log(`⚠️  Missing operation for connection: ${conn.from} → ${conn.to}`);
        failCount++;
      }
    }

    console.log(`📊 Connection Results: ${successCount} successful, ${failCount} failed`);
    return { successCount, failCount };
  }

  async run() {
    console.log('🚀 Starting Enhanced Flow Installation...\n');
    
    if (!(await this.authenticate())) {
      return false;
    }

    try {
      const flowId = await this.createEnhancedFlow();
      
      console.log('\n🎉 Enhanced newsletter flow installed successfully!');
      console.log(`   Flow ID: ${flowId}`);
      console.log(`   Frontend URL: ${this.frontendUrl}`);
      console.log(`   Webhook Secret: ${this.webhookSecret.substring(0, 10)}...`);
      
      console.log('\n📋 Next steps:');
      console.log('1. Go to Settings → Flows → Send Newsletter in Directus admin');
      console.log('2. Verify all operations are connected properly');
      console.log('3. Create a test newsletter and try sending it');
      console.log('4. Check that your frontend endpoints are accessible');
      
      return true;
    } catch (error) {
      console.error('\n❌ Enhanced flow installation failed:', error.message);
      return false;
    }
  }
}

const [,, directusUrl, email, password, frontendUrl, webhookSecret] = process.argv;
const installer = new EnhancedFlowInstaller(directusUrl, email, password, frontendUrl, webhookSecret);
installer.run().then(success => process.exit(success ? 0 : 1));
FLOW_EOF

# Run the enhanced flow installer
cd ../installers
node flow-installer.js "$DIRECTUS_URL" "$EMAIL" "$PASSWORD" "$FRONTEND_URL" "$WEBHOOK_SECRET"

print_success "✅ Enhanced flow installation completed"
EOF

    chmod +x scripts/install-flow.sh
    print_success "✅ Complete flow installer created"
}

create_debug_tools() {
    print_status "📝 Creating complete debug and maintenance tools..."
    
    # Fix flow connections script
    cat > installers/fix-flow-connections.js << 'EOF'
#!/usr/bin/env node
import { createDirectus, rest, authentication, readItems, updateItem } from '@directus/sdk';

class FlowConnectionFixer {
  constructor(directusUrl, email, password) {
    this.directus = createDirectus(directusUrl).with(rest()).with(authentication());
    this.email = email;
    this.password = password;
  }

  async authenticate() {
    await this.directus.login(this.email, this.password);
    console.log('✅ Authenticated successfully');
  }

  async fixConnections() {
    console.log('🔧 Fixing newsletter flow connections...');
    
    // Get newsletter flow
    const flows = await this.directus.request(
      readItems('directus_flows', {
        filter: { name: { _eq: 'Send Newsletter' } }
      })
    );

    if (flows.length === 0) {
      console.error('❌ Newsletter flow not found');
      return false;
    }

    const flow = flows[0];
    console.log(`✅ Found flow: ${flow.name}`);

    // Get operations
    const operations = await this.directus.request(
      readItems('directus_operations', {
        filter: { flow: { _eq: flow.id } },
        sort: ['position_x']
      })
    );

    // Create operation lookup map
    const opMap = {};
    operations.forEach(op => {
      opMap[op.key] = op.id;
      console.log(`   - ${op.name} (${op.key})`);
    });

    // Define correct connections
    const connections = [
      { from: 'validate_newsletter', to: 'compile_mjml' },
      { from: 'compile_mjml', to: 'get_newsletter_data' },
      { from: 'get_newsletter_data', to: 'create_send_record' },
      { from: 'create_send_record', to: 'send_email' },
      { from: 'send_email', to: 'update_newsletter_status' },
      { from: 'update_newsletter_status', to: 'log_success' }
    ];

    // Fix each connection
    let fixed = 0;
    for (const conn of connections) {
      if (opMap[conn.from] && opMap[conn.to]) {
        try {
          await this.directus.request(
            updateItem('directus_operations', opMap[conn.from], {
              resolve: opMap[conn.to]
            })
          );
          console.log(`✅ Connected ${conn.from} → ${conn.to}`);
          fixed++;
        } catch (error) {
          console.log(`❌ Failed to connect ${conn.from}: ${error.message}`);
        }
      } else {
        console.log(`⚠️  Missing operations: ${conn.from} or ${conn.to}`);
      }
    }

    console.log(`🎉 Fixed ${fixed} connections!`);
    return fixed > 0;
  }

  async run() {
    try {
      await this.authenticate();
      return await this.fixConnections();
    } catch (error) {
      console.error('❌ Error:', error.message);
      return false;
    }
  }
}

const [,, directusUrl, email, password] = process.argv;
if (!directusUrl || !email || !password) {
  console.log('Usage: node fix-flow-connections.js <directus-url> <email> <password>');
  process.exit(1);
}

new FlowConnectionFixer(directusUrl, email, password).run()
  .then(success => {
    if (success) {
      console.log('\n🎉 Flow connections fixed successfully!');
      console.log('   Go to Settings → Flows → Send Newsletter to verify');
    }
    process.exit(success ? 0 : 1);
  });
EOF

    # Debug installation script
    cat > scripts/debug-installation.sh << 'EOF'
#!/bin/bash
# scripts/debug-installation.sh - Complete Installation Debugging

set -e
source "$(dirname "$0")/common.sh"

DIRECTUS_URL="$1"
EMAIL="$2"
PASSWORD="$3"
FRONTEND_URL="$4"

print_status "🔍 Running complete newsletter installation debug..."

# Function to test API endpoint
test_api_endpoint() {
    local url="$1"
    local name="$2"
    
    if curl -sf "$url" >/dev/null 2>&1; then
        print_success "✅ $name is accessible"
        return 0
    else
        print_error "❌ $name is not accessible: $url"
        return 1
    fi
}

# Function to check Directus authentication
test_directus_auth() {
    local directus_url="$1"
    local email="$2"
    local password="$3"
    
    print_status "🔐 Testing Directus authentication..."
    
    local response
    response=$(curl -s -X POST "$directus_url/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"password\":\"$password\"}" 2>/dev/null)
    
    if echo "$response" | grep -q "access_token"; then
        print_success "✅ Directus authentication successful"
        return 0
    else
        print_error "❌ Directus authentication failed"
        echo "Response: $response"
        return 1
    fi
}

# Function to check collections
check_collections() {
    local directus_url="$1"
    local token="$2"
    
    print_status "📋 Checking newsletter collections..."
    
    local collections=(
        "newsletter_templates"
        "content_library" 
        "subscribers"
        "mailing_lists"
        "newsletters"
        "newsletter_blocks"
        "block_types"
        "newsletter_sends"
    )
    
    for collection in "${collections[@]}"; do
        local response
        response=$(curl -s -H "Authorization: Bearer $token" \
            "$directus_url/collections/$collection" 2>/dev/null)
        
        if echo "$response" | grep -q "\"collection\":\"$collection\""; then
            print_success "   ✅ $collection exists"
        else
            print_error "   ❌ $collection missing"
        fi
    done
}

# Function to check relationships
check_relationships() {
    local directus_url="$1"
    local token="$2"
    
    print_status "🔗 Checking critical relationships..."
    
    # Check newsletters.blocks relationship
    local response
    response=$(curl -s -H "Authorization: Bearer $token" \
        "$directus_url/fields/newsletters/blocks" 2>/dev/null)
    
    if echo "$response" | grep -q "\"field\":\"blocks\""; then
        print_success "   ✅ newsletters.blocks relationship exists"
    else
        print_error "   ❌ newsletters.blocks relationship missing"
    fi
    
    # Check newsletter_blocks.newsletter_id relationship
    response=$(curl -s -H "Authorization: Bearer $token" \
        "$directus_url/relations" 2>/dev/null)
    
    if echo "$response" | grep -q "newsletter_blocks.*newsletter_id"; then
        print_success "   ✅ newsletter_blocks → newsletters relationship exists"
    else
        print_error "   ❌ newsletter_blocks → newsletters relationship missing"
    fi
}

# Function to check flow
check_flow() {
    local directus_url="$1"
    local token="$2"
    
    print_status "🔄 Checking newsletter flow..."
    
    local response
    response=$(curl -s -H "Authorization: Bearer $token" \
        "$directus_url/flows" 2>/dev/null)
    
    if echo "$response" | grep -q "Send Newsletter"; then
        print_success "   ✅ 'Send Newsletter' flow exists"
        
        # Check flow operations
        local flow_id
        flow_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        local ops_response
        ops_response=$(curl -s -H "Authorization: Bearer $token" \
            "$directus_url/operations?filter[flow][_eq]=$flow_id" 2>/dev/null)
        
        local op_count
        op_count=$(echo "$ops_response" | grep -o '"id":"[^"]*"' | wc -l)
        
        if [ "$op_count" -ge 5 ]; then
            print_success "   ✅ Flow has $op_count operations"
        else
            print_warning "   ⚠️  Flow has only $op_count operations (expected 5+)"
        fi
    else
        print_error "   ❌ 'Send Newsletter' flow not found"
    fi
}

# Function to test frontend endpoints
test_frontend_endpoints() {
    local frontend_url="$1"
    local webhook_secret="$2"
    
    if [ -z "$frontend_url" ]; then
        print_warning "⚠️  No frontend URL provided, skipping endpoint tests"
        return 0
    fi
    
    print_status "🎨 Testing frontend endpoints..."
    
    # Test health endpoint (if exists)
    if test_api_endpoint "$frontend_url/api/health" "Frontend health"; then
        :
    fi
    
    # Test MJML endpoint (expect 401 without auth)
    local mjml_response
    mjml_response=$(curl -s -o /dev/null -w "%{http_code}" "$frontend_url/api/newsletter/compile-mjml" 2>/dev/null)
    
    if [ "$mjml_response" = "401" ]; then
        print_success "   ✅ MJML endpoint exists (returns 401 as expected)"
    elif [ "$mjml_response" = "404" ]; then
        print_error "   ❌ MJML endpoint not found (404)"
    else
        print_warning "   ⚠️  MJML endpoint returned: $mjml_response"
    fi
    
    # Test send endpoint (expect 401 without auth)
    local send_response
    send_response=$(curl -s -o /dev/null -w "%{http_code}" "$frontend_url/api/newsletter/send" 2>/dev/null)
    
    if [ "$send_response" = "401" ]; then
        print_success "   ✅ Send endpoint exists (returns 401 as expected)"
    elif [ "$send_response" = "404" ]; then
        print_error "   ❌ Send endpoint not found (404)"
    else
        print_warning "   ⚠️  Send endpoint returned: $send_response"
    fi
}

# Main debug function
main_debug() {
    print_status "Starting comprehensive debug check..."
    
    # Test basic connectivity
    if [ -n "$DIRECTUS_URL" ]; then
        test_directus_connection "$DIRECTUS_URL"
    fi
    
    if [ -n "$FRONTEND_URL" ]; then
        test_api_endpoint "$FRONTEND_URL" "Frontend"
    fi
    
    # Test authentication and get token
    if [ -n "$DIRECTUS_URL" ] && [ -n "$EMAIL" ] && [ -n "$PASSWORD" ]; then
        if test_directus_auth "$DIRECTUS_URL" "$EMAIL" "$PASSWORD"; then
            # Get auth token for further tests
            local token
            token=$(curl -s -X POST "$DIRECTUS_URL/auth/login" \
                -H "Content-Type: application/json" \
                -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" | \
                grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
            
            if [ -n "$token" ]; then
                check_collections "$DIRECTUS_URL" "$token"
                check_relationships "$DIRECTUS_URL" "$token"
                check_flow "$DIRECTUS_URL" "$token"
            fi
        fi
    fi
    
    # Test frontend endpoints
    test_frontend_endpoints "$FRONTEND_URL" ""
    
    print_status "📊 Debug Summary:"
    print_status "   Directus: ${DIRECTUS_URL:-'Not provided'}"
    print_status "   Frontend: ${FRONTEND_URL:-'Not provided'}"
    print_status "   Auth: ${EMAIL:-'Not provided'}"
    
    print_success "✅ Debug check completed"
    
    print_status "💡 Common fixes:"
    print_status "   • Run: ./deploy.sh fix-flow <directus> <email> <password> <frontend>"
    print_status "   • Check: Settings → Flows → Send Newsletter in Directus admin"
    print_status "   • Verify: Frontend endpoints are accessible from Directus server"
    print_status "   • Ensure: Environment variables match between systems"
}

# Run debug if called directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main_debug
fi
EOF

    chmod +x scripts/debug-installation.sh
    chmod +x installers/fix-flow-connections.js
    
    print_success "✅ Complete debug and maintenance tools created"
}

show_structure() {
    print_status "📂 Complete modular structure created:"
    echo ""
    echo "$DEPLOYMENT_DIR/"
    echo "├── deploy.sh                           # Main orchestrator"
    echo "├── package.json                        # Dependencies"
    echo "├── scripts/"
    echo "│   ├── common.sh                      # Shared functions"
    echo "│   ├── install-collections.sh         # Collection installer"
    echo "│   ├── install-frontend.sh            # Frontend integration"
    echo "│   ├── install-flow.sh                # Flow creation"
    echo "│   └── debug-installation.sh          # Debug tools"
    echo "├── installers/"
    echo "│   ├── newsletter-installer.js        # Complete enhanced installer"
    echo "│   └── fix-flow-connections.js        # Connection fixer"
    echo "└── frontend-integration/"
    echo "    ├── server/api/newsletter/         # Enhanced Nuxt endpoints"
    echo "    ├── types/                         # TypeScript definitions"
    echo "    ├── components/newsletter/         # Vue.js components"
    echo "    ├── composables/                   # Newsletter utilities"
    echo "    └── README.md                      # Integration guide"
    echo ""
}

# Individual installation functions
install_collections() {
    print_status "📦 Installing enhanced collections..."
    bash "$SCRIPTS_DIR/install-collections.sh" "$@"
}

install_collections() {
    print_status "📦 Installing enhanced collections..."
    
    # CRITICAL: Install dependencies FIRST before doing anything else
    if ! install_dependencies; then
        print_error "❌ Cannot proceed without dependencies"
        exit 1
    fi
    
    # Now run the collections installer
    bash "$SCRIPTS_DIR/install-collections.sh" "$@"
}

install_frontend() {
    print_status "🎨 Installing frontend integration..."
    bash "$SCRIPTS_DIR/install-frontend.sh" "$@"
}

install_flow() {
    print_status "🔄 Installing newsletter flow..."
    bash "$SCRIPTS_DIR/install-flow.sh" "$@"
}

debug_installation() {
    print_status "🔍 Running comprehensive debug..."
    bash "$SCRIPTS_DIR/debug-installation.sh" "$@"
}

fix_flow_connections() {
    print_status "🔧 Fixing flow connections..."
    cd "$DEPLOYMENT_DIR"
    node installers/fix-flow-connections.js "$@"
}

show_usage() {
    echo "Complete Modular Newsletter Deployment System v$VERSION"
    echo ""
    echo "✅ ENHANCED FEATURES:"
    echo "   • Newsletter Templates Collection"
    echo "   • Content Library for reusable blocks"
    echo "   • Enhanced subscriber management"
    echo "   • A/B testing and analytics"
    echo "   • Proper blocks relationship with perfect UX"
    echo "   • Modular deployment for easy maintenance"
    echo ""
    echo "Commands:"
    echo "  setup                                                             # Setup complete modular environment"
    echo "  install <directus-url> <email> <password> [frontend-url] [webhook-secret]    # Install enhanced collections"
    echo "  frontend [nuxt-project-path]                                      # Install frontend integration"
    echo "  flow <directus-url> <email> <password> <frontend-url> [webhook-secret]       # Install enhanced flow"
    echo "  full <directus-url> <email> <password> [frontend-url] [webhook-secret] [nuxt-path]  # Complete install"
    echo "  debug <directus-url> <email> <password> [frontend-url]           # Comprehensive debugging"
    echo "  fix-flow <directus-url> <email> <password>                       # Fix flow connections"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 install https://admin.site.com admin@site.com password"
    echo "  $0 frontend /path/to/nuxt/project"
    echo "  $0 flow https://admin.site.com admin@site.com password https://site.com"
    echo "  $0 full https://admin.site.com admin@site.com password https://site.com"
    echo "  $0 debug https://admin.site.com admin@site.com password https://site.com"
    echo "  $0 fix-flow https://admin.site.com admin@site.com password"
    echo ""
    echo "🎯 What you get:"
    echo "  ✅ 8 Enhanced collections with proper relationships"
    echo "  ✅ Newsletter templates for quick creation"
    echo "  ✅ Content library for reusable components"
    echo "  ✅ Enhanced subscriber management with segmentation"
    echo "  ✅ A/B testing and approval workflow support"
    echo "  ✅ Advanced analytics and performance tracking"
    echo "  ✅ Complete frontend integration with Vue.js components"
    echo "  ✅ Automated flows with enhanced error handling"
    echo "  ✅ Modular structure for easy debugging and maintenance"
    echo ""
}

# Main execution
main() {
    case "${1:-}" in
        "setup")
            setup_environment
            ;;
        "install")
            if [ $# -lt 4 ]; then
                print_error "Install requires: <directus-url> <email> <password> [frontend-url] [webhook-secret]"
                show_usage
                exit 1
            fi
            install_collections "$2" "$3" "$4" "$5" "$6"
            ;;
        "frontend") 
            install_frontend "$2"
            ;;
        "flow")
            if [ $# -lt 5 ]; then
                print_error "Flow setup requires: <directus-url> <email> <password> <frontend-url> [webhook-secret]"
                show_usage
                exit 1
            fi
            install_flow "$2" "$3" "$4" "$5" "$6"
            ;;
        "full")
            if [ $# -lt 4 ]; then
                print_error "Full install requires: <directus-url> <email> <password> [frontend-url] [webhook-secret] [nuxt-path]"
                show_usage
                exit 1
            fi
            setup_environment
            install_collections "$2" "$3" "$4" "$5" "$6"
            install_frontend "$7"
            if [ -n "$5" ]; then
                install_flow "$2" "$3" "$4" "$5" "$6"
            fi
            print_success "🎉 Complete modular installation finished!"
            print_warning ""
            print_warning "✅ ENHANCED FEATURES INSTALLED:"
            print_warning "   ✅ Newsletter Templates - Create reusable templates"
            print_warning "   ✅ Content Library - Reusable content blocks"
            print_warning "   ✅ Enhanced Subscribers - Preferences and analytics"
            print_warning "   ✅ Proper Blocks Relationship - Perfect UX"
            print_warning "   ✅ A/B Testing - Optimize performance"
            print_warning "   ✅ Advanced Analytics - Track success"
            print_warning "   ✅ Modular Architecture - Easy maintenance"
            print_warning ""
            print_status "📋 Next steps:"
            print_status "1. Go to Content → Newsletters → Create New"
            print_status "2. You should see working Blocks section"
            print_status "3. Try template selection and content library"
            print_status "4. Copy frontend-integration/ to your Nuxt project"
            print_status "5. Test the complete enhanced workflow"
            print_success "Your enhanced newsletter system is ready! 🚀"
            ;;
        "debug")
            debug_installation "$2" "$3" "$4" "$5"
            ;;
        "fix-flow")
            if [ $# -lt 4 ]; then
                print_error "Flow fix requires: <directus-url> <email> <password>"
                exit 1
            fi
            fix_flow_connections "$2" "$3" "$4"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command_exists node; then
        missing_deps+=("Node.js 16+")
    fi
    
    if ! command_exists npm; then
        missing_deps+=("npm")
    fi
    
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            print_error "  - $dep"
        done
        echo ""
        print_status "Please install missing dependencies and try again."
        exit 1
    fi
}

# Print banner and run
print_banner
check_dependencies
main "$@"