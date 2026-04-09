# Use FrankenPHP Alpine image
FROM dunglas/frankenphp:1.12.1-php8-alpine

# Install WordPress
RUN curl -o wordpress.tar.gz https://wordpress.org/wordpress-6.9.4.tar.gz \
    && tar -xzf wordpress.tar.gz -C /var/www/html --strip-components=1 \
    && rm wordpress.tar.gz

# Install PHP extensions
RUN install-php-extensions \
    pdo_mysql \
    gd \
    intl \
    zip \
    opcache \
    redis \
    mysqli

# PHP upload/execution limits
RUN { \
    echo 'upload_max_filesize=5G'; \
    echo 'post_max_size=5G'; \
    echo 'max_execution_time=300'; \
    echo 'max_input_time=300'; \
} > /usr/local/etc/php/conf.d/uploads.ini

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Expose HTTP port
EXPOSE 80
COPY Caddyfile /etc/frankenphp/Caddyfile
# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile"]