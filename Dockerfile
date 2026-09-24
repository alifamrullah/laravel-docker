# Pilih base image PHP-FPM
FROM php:8.2-fpm

# Install dependensi sistem yang dibutuhkan
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip

# Hapus cache apt agar image lebih ringan
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install ekstensi PHP yang dibutuhkan Laravel
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Ambil dan install Composer dari official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set direktori kerja (working directory)
WORKDIR /var/www