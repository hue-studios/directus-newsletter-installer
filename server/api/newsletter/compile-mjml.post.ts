import mjml2html from "mjml";
import { createDirectus, rest, readItem, updateItem } from "@directus/sdk";
import Handlebars from "handlebars";

export default defineEventHandler(async (event) => {
  try {
    // Get runtime config
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
    const sortedBlocks =
      newsletter.blocks?.sort((a: any, b: any) => a.sort - b.sort) || [];

    // Compile each block
    let compiledBlocks = "";

    for (const block of sortedBlocks) {
      if (!block.block_type?.mjml_template) {
        console.warn(`Block ${block.id} has no MJML template`);
        continue;
      }

      try {
        // Compile handlebars template with block content
        const template = Handlebars.compile(block.block_type.mjml_template);
        const blockMjml = template(block.content || {});

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
        throw createError({
          statusMessage: `Error compiling block ${block.id}: ${errorMessage}`, // ✅ Works!
        });
      }
    }

    // Header and footer partials
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
