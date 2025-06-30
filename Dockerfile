# Dockerfile for Newsletter Installer

FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    curl \
    bash \
    jq \
    && rm -rf /var/cache/apk/*

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy application files
COPY newsletter-installer.js ./
COPY deploy.sh ./
COPY server/ ./server/
COPY types/ ./types/
COPY examples/ ./examples/
COPY docs/ ./docs/
COPY scripts/ ./scripts/
COPY .env.example ./

# Make scripts executable
RUN chmod +x deploy.sh newsletter-installer.js scripts/*.sh

# Create non-root user
RUN addgroup -g 1001 -S newsletter && \
    adduser -S newsletter -u 1001 -G newsletter

# Change ownership
RUN chown -R newsletter:newsletter /app

# Switch to non-root user
USER newsletter

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "console.log('Newsletter installer ready')" || exit 1

# Default command
ENTRYPOINT ["node", "newsletter-installer.js"]

# Usage: docker run newsletter-installer https://directus.com admin@example.com password