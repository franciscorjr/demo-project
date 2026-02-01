# =============================================================================
# Laravel Octane + FrankenPHP - Google Cloud Run
# PHP 8.4 | Multi-stage build for optimized image size
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Composer dependencies
# -----------------------------------------------------------------------------
FROM composer:2 AS composer

WORKDIR /app

# Copy only dependency files first for better cache
COPY composer.json composer.lock ./

# Install dependencies without dev packages
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --ignore-platform-reqs \
    --prefer-dist

# Copy application code
COPY . .

# Generate optimized autoloader without running scripts
# (avoids issues with dev-only service providers like Pail)
RUN composer dump-autoload --optimize --no-dev --no-scripts

# -----------------------------------------------------------------------------
# Stage 2: Node.js build (if using Vite/Mix)
# -----------------------------------------------------------------------------
FROM node:22-alpine AS node

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev 2>/dev/null || echo "No package.json found, skipping npm install"

# Copy source files needed for build
COPY . .

# Build assets (Vite)
RUN npm run build 2>/dev/null || echo "No build script found, skipping asset build"

# -----------------------------------------------------------------------------
# Stage 3: Production image with FrankenPHP
# -----------------------------------------------------------------------------
FROM dunglas/frankenphp:php8.4-alpine AS production

# Build argument for APP_KEY (needed for artisan commands during build)
ARG APP_KEY

# Set environment variables
ENV SERVER_NAME=:8080
ENV FRANKENPHP_CONFIG="worker ./public/index.php"
ENV APP_ENV=production
ENV APP_DEBUG=false
ENV LOG_CHANNEL=stderr
ENV LOG_LEVEL=info
ENV APP_KEY=${APP_KEY}

# Cloud Run specific
ENV PORT=8080

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    curl \
    libpng \
    libjpeg-turbo \
    libwebp \
    freetype \
    icu-libs \
    libzip \
    oniguruma \
    libpq \
    # For healthchecks
    busybox-extras

# Install PHP extensions
RUN install-php-extensions \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    redis \
    gd \
    intl \
    zip \
    bcmath \
    opcache \
    sockets \
    exif

# Copy PHP configuration
COPY docker/php/php.ini $PHP_INI_DIR/conf.d/99-app.ini
COPY docker/php/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

# Copy application from composer stage
COPY --from=composer /app/vendor ./vendor

# Copy built assets from node stage
COPY --from=node /app/public/build ./public/build

# Copy application code
COPY . .

# Create required directories
RUN mkdir -p \
    storage/logs \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    bootstrap/cache

# Clear any cached files that came from COPY
RUN rm -rf bootstrap/cache/*.php \
    && rm -rf storage/framework/cache/data/* \
    && rm -rf storage/framework/views/*.php

# Set proper permissions before artisan commands
RUN chown -R www-data:www-data /app \
    && chmod -R 755 /app/storage \
    && chmod -R 755 /app/bootstrap/cache

# Cache Laravel configurations for production
RUN php artisan package:discover --ansi \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && php artisan event:cache

# Expose Cloud Run required port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start Octane with FrankenPHP, 2 Workers and 500 as Max Request until request a worker
CMD ["php", "artisan", "octane:frankenphp", "--host=0.0.0.0", "--port=8080", "--admin-port=2019", "--workers=2", "--max-requests=500"]
