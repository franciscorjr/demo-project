# =============================================================================
# Laravel + Vite + Wayfinder + FrankenPHP (Cloud Run)
# PHP 8.4 | Multi-stage build
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Composer dependencies
# -----------------------------------------------------------------------------
FROM composer:2 AS composer

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --ignore-platform-reqs \
    --prefer-dist

COPY . .

RUN composer dump-autoload --optimize --no-dev --no-scripts

# -----------------------------------------------------------------------------
# Stage 2: Node dependencies (JS only)
# -----------------------------------------------------------------------------
FROM node:22-alpine AS node

WORKDIR /app

COPY package*.json ./
RUN npm ci

# -----------------------------------------------------------------------------
# Stage 3: Assets build (PHP + Node)
# -----------------------------------------------------------------------------
FROM dunglas/frankenphp:php8.4-alpine AS assets

WORKDIR /app

# Instala Node + npm neste stage
RUN apk add --no-cache nodejs npm

# Copia aplicação
COPY . .

# Copia dependências
COPY --from=composer /app/vendor ./vendor
COPY --from=node /app/node_modules ./node_modules

# Variáveis mínimas para o Artisan não quebrar
ENV APP_ENV=production
ENV APP_DEBUG=false
ENV APP_KEY=base64:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=

# Build dos assets (Vite + Wayfinder)
RUN npm run build

# -----------------------------------------------------------------------------
# Stage 4: Production image (runtime)
# -----------------------------------------------------------------------------
FROM dunglas/frankenphp:php8.4-alpine AS production

ARG APP_KEY

ENV SERVER_NAME=:8080
ENV APP_ENV=production
ENV APP_DEBUG=false
ENV LOG_CHANNEL=stderr
ENV LOG_LEVEL=info
ENV APP_KEY=${APP_KEY}
ENV PORT=8080

WORKDIR /app

# System dependencies
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
    busybox-extras

# PHP extensions
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

# PHP configs
COPY docker/php/php.ini $PHP_INI_DIR/conf.d/99-app.ini
COPY docker/php/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

# App code
COPY . .

# Vendor
COPY --from=composer /app/vendor ./vendor

# Assets compilados
COPY --from=assets /app/public/build ./public/build

# Diretórios necessários
RUN mkdir -p \
    storage/logs \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    bootstrap/cache

# Limpa caches
RUN rm -rf bootstrap/cache/*.php \
    && rm -rf storage/framework/cache/data/* \
    && rm -rf storage/framework/views/*.php

# Permissões
RUN chown -R www-data:www-data /app \
    && chmod -R 755 storage bootstrap/cache

# Cache Laravel
RUN php artisan package:discover --ansi \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && php artisan event:cache

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["php", "artisan", "octane:frankenphp", "--host=0.0.0.0", "--port=8080", "--admin-port=2019", "--workers=2", "--max-requests=500"]
