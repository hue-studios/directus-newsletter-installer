# Troubleshooting Guide

Common issues and solutions for the Directus Newsletter Feature installation and operation.

## Installation Issues

### Authentication Problems

#### "Authentication failed: Invalid credentials"

**Symptoms:**
- Installer fails with authentication error
- Unable to connect to Directus

**Solutions:**
```bash
# 1. Verify credentials manually
curl -X POST https://your-directus.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'

# 2. Check if Directus is accessible
curl -I https://your-directus.com/server/health

# 3. Verify admin user exists in Directus
```

**Common Causes:**
- Wrong email/password
- Directus URL incorrect
- Admin user disabled
- Two-factor authentication enabled

#### "Cannot connect to Directus"

**Symptoms:**
- Connection timeout errors
- Network unreachable errors

**Solutions:**
```bash
# 1. Check if Directus is running
docker ps | grep directus

# 2. Test network connectivity
ping your-directus-domain.com

# 3. Check firewall rules
sudo ufw status

# 4. Verify Docker network (if using Docker)
docker network ls
docker inspect your-network-name
```

### Dependency Issues

#### "Cannot find module 'mjml'"

**Symptoms:**
- Import errors in server endpoints
- Build failures

**Solutions:**
```bash
# 1. Install missing dependencies
npm install mjml @sendgrid/mail handlebars @directus/sdk

# 2. Install TypeScript types
npm install -D @types/mjml

# 3. Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# 4. Check if dependencies are in package.json
cat package.json | grep -A 10 "dependencies"
```

#### "Module not found: @directus/sdk"

**Solutions:**
```bash
# 1. Install latest Directus SDK
npm install @directus/sdk@latest

# 2. Add to transpile in nuxt.config.ts
export default defineNuxtConfig({
  build: {
    transpile: ['@directus/sdk']
  }
})
```

### TypeScript Errors

#### "'config.public.directusUrl' is of type 'unknown'"

**Solution:**
```typescript
// Option 1: Type assertion
const directus = createDirectus(config.public.directusUrl as string)

// Option 2: Add type declarations (types/nuxt.d.ts)
declare module 'nuxt/schema' {
  interface PublicRuntimeConfig {
    directusUrl: string
    siteUrl: string
  }
}
```

#### "'error' is of type 'unknown'"

**Solution:**
```typescript
// Use type guard for error handling
catch (error) {
  const errorMessage = error instanceof Error ? error.message : String(error)
  console.error(errorMessage)
}
```

## Runtime Issues

### MJML Compilation Errors

#### "MJML compilation failed"

**Symptoms:**
- Newsletter HTML not generated
- Compilation endpoint returns errors

**Debugging Steps:**
```bash
# 1. Test MJML endpoint directly
curl -X POST https://your-site.com/api/newsletter/compile-mjml \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1}'

# 2. Check server logs
docker logs your-nuxt-container

# 3. Test MJML compilation manually
node -e "
const mjml = require('mjml');
const result = mjml('<mjml><mj-body><mj-section><mj-column><mj-text>Test</mj-text></mj-column></mj-section></mj-body></mjml>');
console.log(result.html);
"
```

**Common Issues:**
- Invalid MJML syntax in block templates
- Missing Handlebars variables
- Malformed block content JSON

#### "Handlebars template compilation failed"

**Symptoms:**
- Block compilation errors
- Template syntax errors

**Solutions:**
```javascript
// 1. Validate Handlebars template syntax
const Handlebars = require('handlebars');
try {
  const template = Handlebars.compile('{{title}}');
  console.log(template({ title: 'Test' }));
} catch (error) {
  console.error('Template error:', error.message);
}

// 2. Check for common syntax issues
// ❌ Wrong: {{#if title}}{{title}}{{/endif}}
// ✅ Correct: {{#if title}}{{title}}{{/if}}

// 3. Validate JSON in block content
JSON.parse(blockContentString);
```

### Email Sending Issues

#### "SendGrid API key is not valid"

**Symptoms:**
- Email sending fails
- 401 Unauthorized errors

**Solutions:**
```bash
# 1. Verify API key in SendGrid dashboard
# 2. Test API key manually
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [{"to": [{"email": "test@example.com"}]}],
    "from": {"email": "from@example.com"},
    "subject": "Test",
    "content": [{"type": "text/plain", "value": "Test email"}]
  }'

# 3. Check API key permissions in SendGrid
# Must have "Mail Send" permission

# 4. Regenerate API key if needed
```

#### "Rate limit exceeded"

**Symptoms:**
- Some emails fail to send
- 429 Too Many Requests errors

**Solutions:**
```typescript
// 1. Reduce batch size in send endpoint
const batchSize = 50; // Reduce from 100

// 2. Add longer delays between batches
await new Promise(resolve => setTimeout(resolve, 2000));

// 3. Implement exponential backoff
let retryDelay = 1000;
for (let attempt = 0; attempt < 3; attempt++) {
  try {
    await sgMail.send(batchMsg);
    break;
  } catch (error) {
    if (error.code === 429 && attempt < 2) {
      await new Promise(resolve => setTimeout(resolve, retryDelay));
      retryDelay *= 2;
    } else {
      throw error;
    }
  }
}
```

#### "No subscribers found"

**Symptoms:**
- Newsletters show as sent but no emails received
- Zero recipient count

**Solutions:**
```sql
-- 1. Check mailing list relationships
SELECT ml.name, COUNT(mls.mailing_list_id) as subscriber_count
FROM mailing_lists ml
LEFT JOIN mailing_lists_mailing_list mls ON ml.id = mls.mailing_lists_id
GROUP BY ml.id, ml.name;

-- 2. Verify subscriber data
SELECT * FROM mailing_list WHERE status = 'published';

-- 3. Check junction table data
SELECT * FROM mailing_lists_mailing_list;
```

### Database Issues

#### "Collections already exist"

**Symptoms:**
- Installation warnings about existing collections
- Duplicate collection errors

**Solutions:**
```javascript
// The installer safely skips existing collections
// This is normal behavior and not an error

// To force reinstall (destructive):
// 1. Drop existing collections first
// 2. Run installer again

// Or use rollback script:
./scripts/rollback.sh remove https://directus.com admin@example.com password
```

#### "Foreign key constraint fails"

**Symptoms:**
- Cannot create relationships
- Database migration errors

**Solutions:**
```sql
-- 1. Check existing foreign key constraints
SELECT 
  constraint_name,
  table_name,
  column_name,
  referenced_table_name,
  referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = 'directus';

-- 2. Drop conflicting constraints if needed
ALTER TABLE table_name DROP FOREIGN KEY constraint_name;

-- 3. Recreate relationships through installer
```

## Performance Issues

### Slow MJML Compilation

**Symptoms:**
- Newsletter compilation takes too long
- Timeout errors

**Solutions:**
```typescript
// 1. Optimize MJML compilation
const mjmlResult = mjml2html(completeMjml, {
  validationLevel: 'skip', // Skip validation for speed
  beautify: false,         // Disable beautification
  minify: true            // Enable minification
});

// 2. Add timeout to compilation
const compilationPromise = mjml2html(completeMjml);
const timeoutPromise = new Promise((_, reject) => 
  setTimeout(() => reject(new Error('Compilation timeout')), 30000)
);

const result = await Promise.race([compilationPromise, timeoutPromise]);
```

### Large Mailing List Performance

**Symptoms:**
- Slow email sending
- Memory issues

**Solutions:**
```typescript
// 1. Implement smaller batch processing
const batchSize = 25; // Reduce batch size
const delay = 2000;   // Increase delay

// 2. Use streams for large datasets
const subscriberStream = directus.items('mailing_list').readMany({
  limit: -1,
  stream: true
});

// 3. Implement pagination
let page = 1;
const limit = 100;
while (true) {
  const subscribers = await directus.items('mailing_list').readMany({
    page,
    limit,
    filter: { status: { _eq: 'published' } }
  });
  
  if (subscribers.length === 0) break;
  
  // Process batch
  await processBatch(subscribers);
  page++;
}
```

## Directus Configuration Issues

### Flow Not Triggering

**Symptoms:**
- Send button doesn't work
- Flow shows as inactive

**Solutions:**
```bash
# 1. Check flow status in Directus admin
# Settings > Flows > Send Newsletter

# 2. Verify flow trigger configuration
# Trigger: Manual
# Collections: newsletters
# Location: item

# 3. Check user permissions
# Make sure user can execute flows

# 4. Test webhook URLs manually
curl -X POST https://your-site.com/api/newsletter/compile-mjml \
  -H "Authorization: Bearer webhook-secret"
```

### Permission Errors

**Symptoms:**
- Access denied errors
- Cannot create/edit newsletters

**Solutions:**
```bash
# 1. Check user role permissions in Directus
# Settings > Roles & Permissions

# 2. Verify collection permissions
# newsletters: Create, Read, Update
# newsletter_blocks: Create, Read, Update, Delete
# block_types: Read
# mailing_lists: Read

# 3. Check field-level permissions
# All newsletter fields should be accessible
```

## Environment Configuration

### Environment Variables Not Loading

**Symptoms:**
- undefined config values
- Environment variables not accessible

**Solutions:**
```bash
# 1. Check .env file location and format
ls -la .env
cat .env

# 2. Verify nuxt.config.ts configuration
export default defineNuxtConfig({
  runtimeConfig: {
    sendgridApiKey: process.env.SENDGRID_API_KEY,
    // ...
  }
})

# 3. Test environment loading
node -e "console.log(process.env.SENDGRID_API_KEY)"

# 4. Restart application after .env changes
```

### Docker Environment Issues

**Symptoms:**
- Environment variables not passed to containers
- Service communication failures

**Solutions:**
```yaml
# 1. Check docker-compose.yml environment section
services:
  nuxt:
    environment:
      - SENDGRID_API_KEY=${SENDGRID_API_KEY}
    # Or use env_file:
    env_file:
      - .env

# 2. Verify network connectivity
docker network ls
docker exec nuxt-container ping directus-container

# 3. Check service health
docker-compose ps
docker-compose logs nuxt
```

## Debug Mode

### Enable Debug Logging

```typescript
// Add to server endpoints for debugging
export default defineEventHandler(async (event) => {
  if (process.env.NODE_ENV === 'development') {
    console.log('=== DEBUG INFO ===');
    console.log('Headers:', getHeaders(event));
    console.log('Body:', await readBody(event));
    console.log('Config:', useRuntimeConfig());
    console.log('==================');
  }
  
  // ... rest of endpoint
});
```

### Test Individual Components

```bash
# 1. Test Directus connectivity
curl -I https://your-directus.com/server/health

# 2. Test MJML compilation
node -e "
const mjml = require('mjml');
console.log(mjml('<mjml><mj-body><mj-text>Test</mj-text></mj-body></mjml>'));
"

# 3. Test SendGrid API
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"personalizations":[{"to":[{"email":"test@example.com"}]}],"from":{"email":"test@example.com"},"subject":"Test","content":[{"type":"text/plain","value":"Test"}]}'

# 4. Test Nuxt endpoints
curl -X GET https://your-site.com/api/health
```

## Getting Help

If troubleshooting doesn't resolve your issue:

### Gather Information

Before asking for help, collect:

1. **Error Messages**: Full error output
2. **Environment**: OS, Node.js version, Docker versions
3. **Configuration**: Sanitized config files
4. **Logs**: Server logs from the time of error
5. **Steps**: Exact steps to reproduce the issue

### Create Support Request

```bash
# Generate debug report
echo "=== ENVIRONMENT ===" > debug-report.txt
node --version >> debug-report.txt
docker --version >> debug-report.txt
echo "=== DOCKER SERVICES ===" >> debug-report.txt
docker-compose ps >> debug-report.txt
echo "=== NUXT LOGS ===" >> debug-report.txt
docker-compose logs nuxt | tail -50 >> debug-report.txt
echo "=== DIRECTUS LOGS ===" >> debug-report.txt
docker-compose logs directus | tail -50 >> debug-report.txt
```

### Contact Support

- 📧 **Email**: support@youragency.com
- 🐛 **GitHub Issues**: [Create Issue](https://github.com/hue-studios/directus-newsletter-installer/issues)
- 📖 **Documentation**: [Installation Guide](INSTALLATION.md)

Include your debug report and specific error messages for faster resolution.