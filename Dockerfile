FROM dunglas/frankenphp:1.3-php8.4-alpine

# 1. Instalar extensões PHP necessárias
RUN install-php-extensions pdo_pgsql intl zip opcache pcntl bcmath

WORKDIR /app

# 2. Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 3. Copiar arquivos de dependências e código
# Copiamos tudo agora, já que os assets estarão na pasta public/build
COPY . .

# 4. Instalar dependências PHP (sem rodar scripts ainda)
RUN composer install --optimize-autoloader --no-dev --no-interaction --no-scripts

# 5. Gerar o autoload e limpar caches
RUN composer run-script post-autoload-dump

# 6. Permissões
RUN mkdir -p /app/storage/framework/views /app/storage/framework/cache /app/storage/framework/sessions
RUN chmod -R 777 storage bootstrap/cache

ENV AUTOCONF_PROGRAM=frankenphp
ENV LARAVEL_OCTANE_SERVER=frankenphp
EXPOSE 8080

CMD ["php", "artisan", "octane:start", "--server=frankenphp", "--host=0.0.0.0", "--port=8080"]