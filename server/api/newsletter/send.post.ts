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
    const directus = createDirectus(config.public.directusUrl as string).with(
      rest()
    );

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
          "mailing_list.subscribers.subscribers_id.custom_fields",
        ],
      })
    );

    if (!sendRecord || !sendRecord.newsletter.compiled_html) {
      throw createError({
        statusCode: 400,
        statusMessage: "Send record not found or newsletter HTML not compiled",
      });
    }

    const subscribers =
      sendRecord.mailing_list?.subscribers?.filter(
        (sub: any) => sub.subscribers_id.status === "active"
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
    const fromEmail =
      sendRecord.newsletter.from_email || "newsletter@example.com";
    const fromName = sendRecord.newsletter.from_name || "Newsletter";

    // Handle A/B testing
    const isABTest = sendRecord.newsletter.is_ab_test;
    const subjectLine =
      isABTest && sendRecord.send_type === "ab_test_b"
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
      const unsubscribeUrl = `${
        config.public.siteUrl
      }/unsubscribe?email=${encodeURIComponent(
        sub.email
      )}&token=${generateUnsubscribeToken(sub.email)}`;
      const preferencesUrl = `${
        config.public.siteUrl
      }/email-preferences?email=${encodeURIComponent(
        sub.email
      )}&token=${generateUnsubscribeToken(sub.email)}`;

      // Enhanced personalization with custom fields
      let personalizedHtml = sendRecord.newsletter.compiled_html
        .replace(/{{unsubscribe_url}}/g, unsubscribeUrl)
        .replace(/{{preferences_url}}/g, preferencesUrl)
        .replace(
          /{{subscriber_name}}/g,
          sub.name || sub.first_name || "Subscriber"
        )
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
        sendRecord.newsletter.category || "newsletter",
        sendRecord.send_type || "regular",
      ],
    };

    let sentCount = 0;
    let failedCount = 0;

    try {
      // Enhanced batch sending with priority handling
      const batchSize = sendRecord.newsletter.priority === "urgent" ? 50 : 100;
      const delay = sendRecord.newsletter.priority === "urgent" ? 500 : 1000;

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
          status:
            failedCount === 0 ? "sent" : sentCount > 0 ? "sent" : "failed",
          sent_count: sentCount,
          failed_count: failedCount,
          total_recipients: subscribers.length,
          sendgrid_batch_id: batchId,
          sent_at: new Date().toISOString(),
          delivery_rate:
            sentCount > 0 ? (sentCount / subscribers.length) * 100 : 0,
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
          delivery_rate:
            sentCount > 0 ? (sentCount / subscribers.length) * 100 : 0,
          total_recipients: subscribers.length,
        },
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
