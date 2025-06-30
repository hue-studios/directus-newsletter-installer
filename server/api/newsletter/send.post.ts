import sgMail from "@sendgrid/mail";
import { createDirectus, rest, readItem, updateItem } from "@directus/sdk";

export default defineEventHandler(async (event) => {
  try {
    // Get runtime config
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
    const directus = createDirectus(config.public.directusUrl as string).with(
      rest()
    );

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

    // Fetch send record to get specific mailing list
    const sendRecord = await directus.request(
      readItem("newsletter_sends", send_record_id, {
        fields: [
          "*",
          "mailing_list_id.id",
          "mailing_list_id.name",
          "mailing_list_id.subscribers.mailing_list_id.*",
        ],
      })
    );

    const mailingList = sendRecord.mailing_list_id;
    const subscribers = mailingList?.subscribers || [];

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

    // Prepare email data
    const fromEmail = newsletter.from_email || "newsletter@example.com";
    const fromName = newsletter.from_name || "Newsletter";
    const replyTo = newsletter.reply_to || fromEmail;

    // Generate unique batch ID for SendGrid
    const batchId = `newsletter_${newsletter_id}_${Date.now()}`;

    // Helper function to generate unsubscribe tokens
    function generateUnsubscribeToken(email: string): string {
      const crypto = require("node:crypto");
      const data = `${email}:${config.directusWebhookSecret}`;
      return crypto
        .createHash("sha256")
        .update(data)
        .digest("hex")
        .substring(0, 16);
    }

    // Create personalizations for each subscriber
    const personalizations = subscribers.map((subscriber: any) => {
      const unsubscribeUrl = `${config.public.siteUrl}/unsubscribe?email=${encodeURIComponent(subscriber.email)}&token=${generateUnsubscribeToken(subscriber.email)}`;
      const preferencesUrl = `${config.public.siteUrl}/email-preferences?email=${encodeURIComponent(subscriber.email)}&token=${generateUnsubscribeToken(subscriber.email)}`;

      // Replace placeholders in HTML
      let personalizedHtml = newsletter.compiled_html
        .replace(/{{unsubscribe_url}}/g, unsubscribeUrl)
        .replace(/{{preferences_url}}/g, preferencesUrl)
        .replace(/{{subscriber_name}}/g, subscriber.name || "Subscriber")
        .replace(/{{subscriber_email}}/g, subscriber.email);

      return {
        to: [
          {
            email: subscriber.email,
            name: subscriber.name || "",
          },
        ],
      };
    });

    // Prepare the email message
    const msg = {
      from: {
        email: fromEmail,
        name: fromName,
      },
      reply_to: {
        email: replyTo,
        name: fromName,
      },
      subject: newsletter.subject_line,
      html: newsletter.compiled_html,
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
    };

    let sentCount = 0;
    let failedCount = 0;
    const errors: string[] = [];

    try {
      // Send emails in batches to avoid rate limits
      const batchSize = 100;
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

          // Add small delay between batches
          if (batches.length > 1) {
            await new Promise((resolve) => setTimeout(resolve, 1000));
          }
        } catch (batchError: any) {
          failedCount += batch.length;
          errors.push(`Batch error: ${batchError.message}`);
          console.error("SendGrid batch error:", batchError);
        }
      }

      // Update send record with results
      await directus.request(
        updateItem("newsletter_sends", send_record_id, {
          status:
            failedCount === 0 ? "sent" : sentCount > 0 ? "sent" : "failed",
          sent_count: sentCount,
          failed_count: failedCount,
          sendgrid_batch_id: batchId,
          sent_at: new Date().toISOString(),
          error_log: errors.length > 0 ? errors.join("\n") : null,
        })
      );

      return {
        success: true,
        message: `Newsletter sent to ${sentCount} recipients`,
        sent_count: sentCount,
        failed_count: failedCount,
        batch_id: batchId,
      };
    } catch (error: any) {
      console.error("SendGrid error:", error);

      // Update send record as failed
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
    console.error("Newsletter send error:", error);

    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || "Email sending failed",
    });
  }
});
