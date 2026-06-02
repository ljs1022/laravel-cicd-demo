# 使用輕量級的 PHP 8.3 FPM 官方映像檔作為基底
FROM php:8.3-fpm

# 安裝系統層級依賴與必要的 PHP 擴充套件
RUN apt-get update && apt-get install -y \
    curl \
    zip \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 從 Composer 官方映像檔中把 composer 執行檔複製過來
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 設定容器內的工作目錄
WORKDIR /var/www

# 把本機原始碼複製到容器內 (此時會自動過濾掉 .dockerignore 裡的東西)
COPY . .

# 執行 Composer 安裝依賴 (核心關鍵：--no-dev 不裝測試工具，--optimize-autoloader 提升載入效能)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# 設定資料夾權限，讓 PHP-FPM (身分為 www-data) 有權限寫入 log 與快取
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# 出於資安考量，後續執行不再使用 root 權限，切換為 www-data
USER www-data

# 暴露 9000 port 供 Nginx 串接
EXPOSE 9000

CMD ["php-fpm"]
