# Directus Newsletter Flow Setup Guide

## Overview

This guide will help you set up the automated newsletter sending flow in Directus. The flow will:

1. **Validate** the newsletter is ready to send
2. **Compile MJML** from blocks into HTML
3. **Get mailing list data** for the newsletter
4. **Create send records** for tracking
5. **Send emails** via your frontend API
6. **Update status** when complete

## Prerequisites

- Newsletter collections installed in Directus
- Frontend endpoints deployed and accessible at your domain
- Environment variables configured in your frontend
- At least one test mailing list created
- Test newsletter with blocks created

## Step-by-Step Flow Creation

### 1. Create the Flow

1. **Log into Directus Admin**
2. **Go to Settings → Flows**
3. **Click "Create Flow"**
4. **Configure basic settings:**
   - **Name**: `Send Newsletter`
   - **Icon**: `send`
   - **Color**: `#00D4AA`
   - **Status**: `Active`
   - **Trigger**: `Manual`
   - **Collections**: Select `newsletters`
   - **Location**: `Item`
   - **Require Confirmation**: `Yes`
   - **Confirmation Description**: `This will send the newsletter to all selected mailing lists. Are you sure you want to continue?`

### 2. Add Flow Operations

Create these operations in this exact order:

#### Operation 1: Validate Newsletter
- **Type**: `Condition`
- **Name**: `Validate Newsletter`
- **Position**: Start of flow
- **Filter**:
```json
{
  "_and": [
    {
      "status": {
        "_eq": "ready"
      }
    },
    {
      "subject_line": {
        "_nnull": true
      }
    },
    {
      "from_email": {
        "_nnull": true
      }
    }
  ]
}
```
- **Resolve**: Connect to "Compile MJML"
- **Reject**: Connect to "Log Validation Error"

#### Operation 2: Log Validation Error
- **Type**: `Log`
- **Name**: `Log Validation Error`
- **Level**: `Error`
- **Message**: `Newsletter validation failed: Newsletter must be in 'ready' status with subject line and from email configured.`

#### Operation 3: Compile MJML
- **Type**: `Webhook`
- **Name**: `Compile MJML`
- **Method**: `POST`
- **URL**: `https://theagency-ny.com/api/newsletter/compile-mjml`
- **Headers**:
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer YOUR_WEBHOOK_SECRET_HERE"
}
```
- **Body**:
```json
{
  "newsletter_id": "{{$trigger.body.keys[0]}}"
}
```
- **Resolve**: Connect to "Get Newsletter Data"
- **Reject**: Connect to "Log Compile Error"

#### Operation 4: Log Compile Error
- **Type**: `Log`
- **Name**: `Log Compile Error`
- **Level**: `Error`
- **Message**: `MJML compilation failed: {{compile_mjml.$last.error}}`

#### Operation 5: Get Newsletter Data
- **Type**: `Read Data`
- **Name**: `Get Newsletter Data`
- **Collection**: `newsletters`
- **Key**: `{{$trigger.body.keys[0]}}`
- **Query**:
```json
{
  "fields": [
    "id",
    "title",
    "compiled_html"
  ]
}
```
- **Resolve**: Connect to "Create Send Record"

#### Operation 6: Create Send Record
- **Type**: `Create Data`
- **Name**: `Create Send Record`
- **Collection**: `newsletter_sends`
- **Payload**:
```json
{
  "newsletter_id": "{{$trigger.body.keys[0]}}",
  "mailing_list_id": 1,
  "status": "pending",
  "total_recipients": 1
}
```
- **Note**: *The mailing_list_id and total_recipients are hardcoded for simplicity. In production, you'll want to modify this to use actual mailing list relationships.*
- **Resolve**: Connect to "Send Email"

#### Operation 7: Send Email
- **Type**: `Webhook`
- **Name**: `Send Email`
- **Method**: `POST`
- **URL**: `https://theagency-ny.com/api/newsletter/send`
- **Headers**:
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer YOUR_WEBHOOK_SECRET_HERE"
}
```
- **Body**:
```json
{
  "newsletter_id": "{{$trigger.body.keys[0]}}",
  "send_record_id": "{{create_send_record.id}}"
}
```
- **Resolve**: Connect to "Update Newsletter Status"
- **Reject**: Connect to "Log Send Error"

#### Operation 8: Log Send Error
- **Type**: `Log`
- **Name**: `Log Send Error`
- **Level**: `Error`
- **Message**: `Email sending failed: {{send_email.$last.error}}`
- **Resolve**: Connect to "Update Send Failed"

#### Operation 9: Update Send Failed
- **Type**: `Update Data`
- **Name**: `Update Send Failed`
- **Collection**: `newsletter_sends`
- **Key**: `{{create_send_record.id}}`
- **Payload**:
```json
{
  "status": "failed",
  "error_log": "{{send_email.$last.error}}"
}
```

#### Operation 10: Update Newsletter Status
- **Type**: `Update Data`
- **Name**: `Update Newsletter Status`
- **Collection**: `newsletters`
- **Key**: `{{$trigger.body.keys[0]}}`
- **Payload**:
```json
{
  "status": "sent"
}
```
- **Resolve**: Connect to "Log Success"

#### Operation 11: Log Success
- **Type**: `Log`
- **Name**: `Log Success`
- **Level**: `Info`
- **Message**: `Newsletter '{{get_newsletter_data.title}}' sent successfully`

## Environment Variables Required

### Frontend Environment (.env in your Nuxt project)
```env
# Required in your frontend environment
DIRECTUS_URL=https://admin.theagency-ny.com
DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret-here
SENDGRID_API_KEY=SG.your-sendgrid-api-key
NUXT_SITE_URL=https://theagency-ny.com
```

### Directus Environment (optional)
You may want to add these for reference, but they're not required for the flow:
```env
# Optional in Directus environment for reference
FRONTEND_URL=https://theagency-ny.com
```

**Important**: Replace `YOUR_WEBHOOK_SECRET_HERE` in the flow operations with your actual webhook secret from the frontend environment.

## Testing the Flow

### 1. Create Test Mailing List

1. **Go to Content → Mailing Lists**
2. **Create new mailing list:**
   - **Name**: "Test List"
   - **Description**: "For testing newsletters"
   - **Status**: "Active"

### 2. Create Test Newsletter

1. **Go to Content → Newsletters**
2. **Create new newsletter:**
   - **Title**: "Test Newsletter"
   - **Subject Line**: "Test Email"
   - **From Name**: "Your Name"
   - **From Email**: "test@yoursite.com"
   - **Status**: "Ready to Send"

### 3. Add Content Blocks

1. **Add some blocks to your newsletter:**
   - Add a "Hero Section" block
   - Add a "Text Block" with content
   - Configure the block content with actual text

### 4. Send Test

1. **Set newsletter status to "Ready to Send"**
2. **Click the "Send Newsletter" button** (should appear in the top right)
3. **Confirm sending** in the popup dialog
4. **Watch the flow execute** in Settings → Flows → Send Newsletter → Activity

## Troubleshooting

### Flow Not Visible
- Check that flow status is "Active"
- Verify trigger is set to "Manual" with "newsletters" collection
- Ensure user has permission to execute flows
- Check that the newsletter has status "ready"

### Webhook Failures
- Verify frontend URLs are accessible from your Directus server
- Check webhook secret matches between flow operations and frontend environment
- Test endpoints manually:

```bash
# Test MJML compilation (replace with your actual domain and secret)
curl -X POST https://theagency-ny.com/api/newsletter/compile-mjml \
  -H "Authorization: Bearer your-webhook-secret" \
  -H "Content-Type: application/json" \
  -d '{"newsletter_id": 1}'

# Expected response:
# {"success": true, "message": "MJML compiled successfully"}

# Test email sending
curl -X POST https://theagency-ny.com/api/newsletter/send \
  -H "Authorization: Bearer your-webhook-secret" \
  -H "Content-Type: application/json" \
  -d '{"newsletter_id": 1, "send_record_id": 1}'

# Expected response:
# {"success": true, "message": "Newsletter sent successfully", "sent_count": 1}
```

### Permission Issues
- Verify user role has permissions for:
  - `newsletters`: Read, Update
  - `newsletter_sends`: Create, Read, Update
  - `newsletter_blocks`: Read, Update
  - `mailing_lists`: Read
  - Flow execution permissions

### Flow Execution Errors
- Check **Settings → Flows → Send Newsletter → Activity** for detailed error logs
- Verify all operation connections are correct
- Test individual webhook URLs outside of Directus
- Check that your frontend server is running and accessible

### Common Error Messages

**"Newsletter validation failed"**
- Newsletter status must be "ready"
- Subject line must be filled
- From email must be filled

**"MJML compilation failed"**
- Frontend endpoint not accessible
- Webhook secret mismatch
- Newsletter has no blocks or invalid block data

**"Email sending failed"**
- SendGrid API key issues
- Frontend environment variables not set
- Send record not created properly

## Alternative: Simplified Flow for Testing

If the full flow is too complex, start with this minimal version:

### Simple Flow Operations:
1. **Validate Newsletter** (condition)
2. **Compile MJML** (webhook to your frontend)
3. **Log Result** (log operation)

This will test your webhook connectivity and MJML compilation without the complexity of send records and email delivery.

## Advanced Configuration

### Multiple Mailing Lists Support

To support multiple mailing lists per newsletter, you'll need to:

1. **Add Mailing List Relationship** to newsletters
2. **Modify Get Newsletter Data** operation to include mailing lists:
```json
{
  "fields": [
    "id",
    "title",
    "compiled_html",
    "mailing_lists.mailing_lists_id.id",
    "mailing_lists.mailing_lists_id.name",
    "mailing_lists.mailing_lists_id.subscriber_count"
  ]
}
```

3. **Use Loops** in the flow to create multiple send records
4. **Update Create Send Record** to use dynamic data:
```json
{
  "newsletter_id": "{{$trigger.body.keys[0]}}",
  "mailing_list_id": "{{get_newsletter_data.mailing_lists[0].mailing_lists_id.id}}",
  "status": "pending",
  "total_recipients": "{{get_newsletter_data.mailing_lists[0].mailing_lists_id.subscriber_count}}"
}
```

### Scheduled Sending

To add scheduled sending:
1. Add a `scheduled_at` field to newsletters collection
2. Change flow trigger to "Schedule" instead of "Manual"
3. Configure cron expression: `0 * * * *` (every hour)
4. Add condition to check if `scheduled_at <= now()`

### Error Notifications

To get notified of failures:
1. Add email notification operations on error paths
2. Create Slack webhook operations for alerts
3. Set up monitoring dashboard for send statistics

## Production Considerations

### Rate Limiting
- Configure SendGrid rate limits in your frontend
- Add delays between batch sends
- Monitor API usage and quotas

### Monitoring
- Set up logging for all flow executions
- Monitor newsletter_sends collection for failed sends
- Create dashboard for send statistics

### Security
- Use strong webhook secrets
- Restrict Directus flow permissions
- Monitor for unauthorized flow executions

## Support

If you encounter issues:
1. Check the Activity logs in Directus flows (Settings → Flows → Send Newsletter → Activity)
2. Test webhook endpoints independently with curl commands
3. Verify all environment variables are set correctly
4. Check server logs for detailed error messages
5. Ensure your frontend server is accessible from your Directus server

**Remember**: The frontend endpoints must be accessible from your Directus server for webhooks to work. Test connectivity between servers if webhooks fail.

For additional help, see:
- [Installation Guide](INSTALLATION.md) for setup issues
- [Troubleshooting Guide](TROUBLESHOOTING.md) for detailed debugging
- [Quick Reference](../examples/flow-quick-reference.md) for copy-paste commands