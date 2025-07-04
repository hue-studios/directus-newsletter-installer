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
    const directus = createDirectus(config.public.directusUrl as string).with(
      rest()
    );

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
          "template_id.category",
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
    const sortedBlocks =
      newsletter.blocks?.sort((a: any, b: any) => a.sort - b.sort) || [];

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
          title: block.title || block.content?.title || "",
          subtitle: block.subtitle || block.content?.subtitle || "",
          text_content:
            block.text_content ||
            block.content?.content ||
            block.content?.text_content ||
            "",

          // Image fields
          image_url: block.image_url || block.content?.image_url || "",
          image_alt_text:
            block.image_alt_text ||
            block.content?.alt_text ||
            block.content?.image_alt_text ||
            "",
          image_caption:
            block.image_caption ||
            block.content?.caption ||
            block.content?.image_caption ||
            "",

          // Button fields
          button_text: block.button_text || block.content?.button_text || "",
          button_url: block.button_url || block.content?.button_url || "",

          // Styling fields with enhanced defaults
          background_color:
            block.background_color ||
            block.content?.background_color ||
            "#ffffff",
          text_color:
            block.text_color || block.content?.text_color || "#333333",
          text_align: block.text_align || block.content?.text_align || "center",

          // Layout fields
          padding: block.padding || block.content?.padding || "20px 0",
          font_size: block.font_size || block.content?.font_size || "14px",

          // Dynamic personalization variables
          company_name: "{{company_name}}",
          subscriber_name: "{{subscriber_name}}",
          unsubscribe_url: "{{unsubscribe_url}}",
          preferences_url: "{{preferences_url}}",
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
        const errorMessage =
          error instanceof Error ? error.message : String(error);
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
        <mj-image src="${
          config.public.siteUrl || config.public.directusUrl
        }/assets/logo.png" alt="Newsletter" width="200px" align="center" />
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
      has_template: !!newsletter.template_id,
    };
  } catch (error: any) {
    console.error("Enhanced MJML compilation error:", error);

    throw createError({
      statusCode: error.statusCode || 500,
      statusMessage: error.statusMessage || "Internal server error",
    });
  }
});
