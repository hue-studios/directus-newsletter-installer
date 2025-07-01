# Flow Quick Reference

Quick commands and URLs for newsletter flow setup. For complete setup instructions, see [docs/FLOW_SETUP.md](../docs/FLOW_SETUP.md).

## Essential Webhook URLs

Replace `your-frontend.com` with your actual frontend domain:

```
MJML Compile: https://your-frontend.com/api/newsletter/compile-mjml
Send Email:   https://your-frontend.com/api/newsletter/send
```

## Required Headers

For all webhook operations:

```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer YOUR_WEBHOOK_SECRET"
}
```

## Flow Operation Bodies

### MJML Compilation Body
```json
{
  "newsletter_id": "{{$trigger.body.keys[0]}}"
}
```

### Send Email Body
```json
{
  "newsletter_id": "{{$trigger.body.keys[0]}}",
  "send_record_id": "{{create_send_record.id}}"
}
```

## Test Commands

### Test MJML Compilation
```bash
curl -X POST https://your-frontend.com/api/newsletter/compile-mjml \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1}'
```

### Test Email Sending
```bash
curl -X POST https://your-frontend.com/api/newsletter/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-webhook-secret" \
  -d '{"newsletter_id": 1, "send_record_id": 1}'
```

## Environment Variables

Ensure these are set in your frontend environment:

```env
DIRECTUS_URL=https://admin.your-site.com
DIRECTUS_WEBHOOK_SECRET=your-secure-webhook-secret
SENDGRID_API_KEY=SG.your-sendgrid-api-key
NUXT_SITE_URL=https://your-frontend.com
```

## Quick Flow Operations Checklist

1. **Validate Newsletter** (Condition)
   - Status = "ready"
   - Subject line exists
   - From email exists

2. **Compile MJML** (Webhook)
   - URL: `https://your-frontend.com/api/newsletter/compile-mjml`
   - Method: POST
   - Headers: Authorization + Content-Type

3. **Create Send Record** (Create Data)
   - Collection: `newsletter_sends`
   - Status: "pending"

4. **Send Email** (Webhook)
   - URL: `https://your-frontend.com/api/newsletter/send`
   - Method: POST
   - Headers: Authorization + Content-Type

5. **Update Status** (Update Data)
   - Collection: `newsletters`
   - Set status to "sent"

## Quick Troubleshooting

### Flow Not Triggering
- Check flow status is "Active"
- Verify newsletter status is "ready"
- Ensure user has flow execution permissions

### Webhook Failures
- Test URLs manually with curl commands above
- Verify webhook secret matches frontend environment
- Check frontend endpoints are accessible from Directus server

### Expected Responses

**Successful MJML Compilation:**
```json
{
  "success": true,
  "message": "MJML compiled successfully"
}
```

**Successful Email Send:**
```json
{
  "success": true,
  "message": "Newsletter sent successfully",
  "sent_count": 1
}
```

## Minimal Test Flow

For initial testing, create a simplified 3-operation flow:
1. **Validate** → 2. **Compile MJML** → 3. **Log Result**

This tests webhook connectivity without the complexity of email sending.

---

📖 **Need more details?** See the complete [Flow Setup Guide](../docs/FLOW_SETUP.md) for step-by-step instructions with screenshots and advanced configurations.