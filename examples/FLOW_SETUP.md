# Directus Flow Setup Guide

This guide explains how to configure the newsletter sending flow in Directus using the provided flow configuration.

## Overview

The newsletter flow automates the entire process from MJML compilation to email delivery:

1. **Validation** - Ensures newsletter is ready to send
2. **MJML Compilation** - Converts blocks to HTML email
3. **Mailing List Processing** - Gets subscriber data  
4. **Send Record Creation** - Tracks sending progress
5. **Email Delivery** - Sends via SendGrid
6. **Status Updates** - Updates newsletter and send records

## Setup Methods

### Method 1: Manual Flow Creation (Recommended)

#### Step 1: Create the Flow

1. Log into Directus Admin
2. Go to **Settings** → **Flows**
3. Click **Create Flow**
4. Configure basic settings:
   - **Name**: `Send Newsletter`
   - **Icon**: `send` 
   - **Color**: `#00D4AA`
   - **Status**: `Active`
   - **Trigger**: `Manual`
   - **Collections**: `newsletters`
   - **Location**: `Item`
   - **Require Confirmation**: `Yes`
   - **Confirmation Description**: `This will send the newsletter to all selected mailing lists. Are you sure?`

#### Step 2: Add Operations

Add these operations in order, connecting them as shown:

**1. Newsletter Validation**
- **Type**: Condition
- **Name**: `Validate Newsletter`
- **Filter**:
  ```json
  {
    "_and": [
      {"status": {"_eq": "ready"}},
      {"blocks": {"_nnull": true}},
      {"mailing_lists": {"_nnull": true}},
      {"subject_line": {"_nnull": true}}
    ]
  }
  ```

**2. MJML Compilation** (on validation success)
- **Type**: Webhook
- **Name**: `Compile MJML`
- **Method**: `POST`
- **URL**: `{{$env.NUXT_SITE_URL}}/api/newsletter/compile-mjml`
- **Headers**:
  ```json
  {
    "Content-Type": "application/json",
    "Authorization": "Bearer {{$env.DIRECTUS_WEBHOOK_SECRET}}"
  }
  ```
- **Body**:
  ```json
  {
    "newsletter_id": "{{$trigger.body.keys[0]}}"
  }
  ```

**3. Get Mailing Lists** (on compilation success)
- **Type**: Read Data
- **Name**: `Get Mailing Lists`
- **Collection**: `newsletters`
- **Key**: `{{$trigger.body.keys[0]}}`
- **Query**:
  ```json
  {
    "fields": [
      "id",
      "title", 
      "mailing_lists.mailing_lists_id.id",
      "mailing_lists.mailing_lists_id.name",
      "mailing_lists.mailing_lists_id.subscribers.mailing_list_id.*"
    ]
  }
  ```

**4. Create Send Records** (after getting lists)
- **Type**: Create Data
- **Name**: `Create Send Records`
- **Collection**: `newsletter_sends`
- **Payload**:
  ```json
  {
    "newsletter_id": "{{$trigger.body.keys[0]}}",
    "mailing_list_id": "{{get_mailing_lists.mailing_lists.mailing_lists_id.id}}",
    "status": "pending",
    "total_recipients": "{{get_mailing_lists.mailing_lists.mailing_lists_id.subscribers.length}}"
  }
  ```

**5. Send Emails** (after creating records)
- **Type**: Webhook
- **Name**: `Send Emails`
- **Method**: `POST`
- **URL**: `{{$env.NUXT_SITE_URL}}/api/newsletter/send`
- **Headers**:
  ```json
  {
    "Content-Type": "application/json",
    "Authorization": "Bearer {{$env.DIRECTUS_WEBHOOK_SECRET}}"
  }
  ```
- **Body**:
  ```json
  {
    "newsletter_id": "{{$trigger.body.keys[0]}}",
    "send_record_id": "{{create_send_records.id}}"
  }
  ```

**6. Update Newsletter Status** (on send success)
- **Type**: Update Data
- **Name**: `Update Newsletter Status`
- **Collection**: `newsletters`
- **Key**: `{{$trigger.body.keys[0]}}`
- **Payload**:
  ```json
  {
    "status": "sent"
  }
  ```

**7. Log Success** (after status update)
- **Type**: Log
- **Name**: `Log Success`
- **Level**: `Info`
- **Message**: `Newsletter sent successfully to {{get_mailing_lists.mailing_lists.length}} mailing list(s)`

#### Error Handling Operations

**Validation Error Log** (on validation failure)
- **Type**: Log
- **Name**: `Log Validation Error`
- **Level**: `Error`
- **Message**: `Newsletter validation failed: Must be in 'ready' status with blocks, mailing lists, and subject line`

**Compile Error Log** (on MJML failure)
- **Type**: Log
- **Name**: `Log Compile Error`
- **Level**: `Error`
- **Message**: `MJML compilation failed: {{compile_mjml.$last.error}}`

**Send Error Handling** (on email failure)
- **Type**: Log
- **Name**: `Log Send Error`
- **Level**: `Error`
- **Message**: `Email sending failed: {{send_emails.$last.error}}`

**Update Failed Status** (after send error)
- **Type**: Update Data
- **Name**: `Update Send Failed`
- **Collection**: `newsletter_sends`
- **Key**: `{{create_send_records.id}}`
- **Payload**:
  ```json
  {
    "status": "failed",
    "error_log": "{{send_emails.$last.error}}"
  }
  ```

### Method 2: Import Flow Configuration (Advanced)

⚠️ **Note**: Direct flow import/export is not available in all Directus versions. Use Method 1 for guaranteed compatibility.

If your Directus version supports flow import:

1. Download `directus-flow.json` from this repository
2. In Directus Admin, go to **Settings** → **Flows**
3. Look for import/export options
4. Import the JSON configuration
5. Update environment variables as needed

## Environment Variables Required

Ensure these environment variables are set in your Directus instance:

```env
NUXT_SITE_URL=https://your-nuxt-site.com
DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret
```

## Testing the Flow

### Step 1: Create Test Newsletter

1. Go to **Content** → **Newsletters**
2. Create a new newsletter:
   - **Title**: "Test Newsletter"
   - **Subject Line**: "Test Email" 
   - **From Name**: "Your Name"
   - **From Email**: "test@yoursite.com"

### Step 2: Add Content Blocks

1. Add blocks to your newsletter:
   - Add a "Hero Section" block
   - Add a "Text Block" with some content
   - Configure block content as needed

### Step 3: Select Mailing Lists

1. Create a test mailing list with your email
2. Assign the mailing list to your newsletter

### Step 4: Send Test

1. Set newsletter status to **"Ready to Send"**
2. Click the **"Send Newsletter"** button
3. Confirm sending in the popup
4. Monitor the flow execution in **Activity** logs

## Flow Execution Monitoring

### Check Flow Status

1. Go to **Settings** → **Flows**
2. Click on "Send Newsletter" flow
3. View **Activity** tab for execution logs

### Monitor Send Records

1. Go to **Content** → **Newsletter Sends**
2. Check status of send records:
   - `pending` → `sending` → `sent` (success)
   - `pending` → `failed` (error)

### View Logs

1. Go to **Activity** in main navigation
2. Filter by **Type**: `Flow`
3. Look for flow execution entries

## Troubleshooting

### Flow Not Triggering

**Check:**
- Flow status is "Active"
- Newsletter status is "ready"
- User has permission to execute flows
- Newsletter has blocks and mailing lists

### Webhook Failures

**Common Issues:**
- Incorrect `NUXT_SITE_URL` environment variable
- Wrong `DIRECTUS_WEBHOOK_SECRET`
- Nuxt endpoints not accessible
- Missing required dependencies in Nuxt project

**Test Webhook URLs:**
```bash
# Test MJML compilation
curl -X POST https://your-site.com/api/newsletter/compile-mjml \
  -H "Authorization: Bearer your-webhook-secret" \
  -H "Content-Type: application/json" \
  -d '{"newsletter_id": 1}'

# Test email sending  
curl -X POST https://your-site.com/api/newsletter/send \
  -H "Authorization: Bearer your-webhook-secret" \
  -H "Content-Type: application/json" \
  -d '{"newsletter_id": 1, "send_record_id": 1}'
```

### Data Access Issues

**Check Collection Permissions:**
- User role has read/write access to:
  - `newsletters`
  - `newsletter_blocks` 
  - `newsletter_sends`
  - `mailing_lists`
  - `block_types`

### Email Delivery Problems

**Check:**
- SendGrid API key is valid
- From email is verified in SendGrid
- Mailing lists have active subscribers
- SendGrid account has sending capacity

## Advanced Configuration

### Custom Error Handling

Add additional error handling operations:

**Retry Logic**
- Add delay operations
- Implement retry counters
- Create escalation notifications

**Notifications**
- Send admin notifications on failure
- Create Slack/email alerts
- Log to external monitoring systems

### Performance Optimization

For large mailing lists:

**Batch Processing**
- Split large lists into smaller batches
- Add delays between send operations
- Implement queue management

**Monitoring**
- Track sending rates
- Monitor API rate limits
- Set up performance alerts

## Support

If you encounter issues with flow setup:

1. Check the [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
2. Verify environment variables are set correctly
3. Test webhook endpoints independently
4. Review Directus activity logs for detailed errors

For additional help, contact: support@youragency.com