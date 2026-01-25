FROM dunglas/frankenphp:1.3-php8.4-alpine

# 1. Instalar extensões PHP necessárias
RUN install-php-extensions pdo_pgsql intl zip opcache pcntl bcmath

# 2. Garantir que o binário do FrankenPHP seja encontrado pelo Octane
# Algumas imagens Alpine o colocam em caminhos diferentes; isso cria um atalho global
RUN ln -s /usr/local/bin/frankenphp /usr/bin/frankenphp

WORKDIR /app

# 3. Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Copiar código (Assets buildados localmente devem estar em public/build)
COPY . .

# 5. Instalar dependências e garantir binários do Octane
RUN composer install --optimize-autoloader --no-dev --no-interaction --no-scripts
RUN composer run-script post-autoload-dump

# Força a instalação do binário do FrankenPHP dentro do vendor se ele não existir
RUN php artisan octane:install --server=frankenphp

# 6. Permissões e pastas de sistema
RUN mkdir -p storage/framework/views storage/framework/cache storage/framework/sessions
RUN chmod -R 777 storage bootstrap/cache

# Variáveis de ambiente para o Runtime
ENV AUTOCONF_PROGRAM=frankenphp
ENV LARAVEL_OCTANE_SERVER=frankenphp
ENV OCTANE_STATE_FILE=/tmp/octane-state.json

EXPOSE 8080

# Usamos o entrypoint nativo do FrankenPHP se possível, ou o artisan
CMD ["php", "artisan", "octane:start", "--server=frankenphp", "--host=0.0.0.0", "--port=8080"]