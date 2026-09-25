# STAGE 1: Build Dependency Composer
FROM composer:2.6 AS vendor

WORKDIR /app

# Optimasi Caching Layer: Salin file composer lebih dulu sebelum seluruh kodingan.
# Jika kodingan berubah tapi dependency tetap, Docker tidak perlu download ulang vendor!
COPY composer.json composer.lock ./

# Install dependency tanpa paket dev (untuk security & ukuran lebih kecil)
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --ignore-platform-reqs \
    --optimize-autoloader \
    --no-scripts

# STAGE 2: Build Frontend Assets (Vite/Node)
FROM node:20-alpine AS assets

WORKDIR /app

# Optimasi Caching Layer untuk NPM
COPY package.json package-lock.json* ./
RUN npm install

# Salin kodingan dan jalankan proses build assets
COPY . .
RUN npm run build

# STAGE 3: Runtime Image Production (Ringan & Aman)
FROM php:8.2-fpm-alpine

# Install library runtime & ekstensi PHP di Alpine, lalu hapus cache apk dalam 1 layer
RUN apk add --no-cache \
    libpng-dev \
    libzip-dev \
    zip \
    && docker-php-ext-install pdo_mysql bcmath gd zip \
    && rm -rf /var/cache/apk/*

WORKDIR /var/www

# 1. Salin kode aplikasi utama
COPY . /var/www

# 2. Salin HANYA hasil build vendor dari Stage 1 (tanpa membawa aplikasi Composer)
COPY --from=vendor /app/vendor /var/www/vendor

# 3. Salin HANYA hasil build assets dari Stage 2 (tanpa membawa Node.js & node_modules)
COPY --from=assets /app/public/build /var/www/public/build

# Security: Atur kepemilikan file dan jalankan PHP-FPM sebagai non-root user (www-data)
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

USER www-data

EXPOSE 9000
CMD ["php-fpm"]