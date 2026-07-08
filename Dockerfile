# Use FrankenPHP Alpine image
FROM dunglas/frankenphp:1.12.4-php8-alpine

# Install WordPress
RUN curl -o wordpress.tar.gz https://wordpress.org/wordpress-6.9.4.tar.gz \
    && tar -xzf wordpress.tar.gz -C /var/www/html --strip-components=1 \
    && rm wordpress.tar.gz

# Update CA certificates
RUN apk upgrade --no-cache && apk add --no-cache ca-certificates openssl curl \
    && curl -o /usr/local/share/ca-certificates/isrg-root-yr.crt \
        https://letsencrypt.org/certs/gen-y/root-yr.pem \
    && curl -o /usr/local/share/ca-certificates/isrg-root-ye.crt \
        https://letsencrypt.org/certs/gen-y/root-ye.pem \
    && curl -o /usr/local/share/ca-certificates/letsencrypt-r13.crt \
        https://letsencrypt.org/certs/2024/r13.pem \
    && update-ca-certificates

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
    echo 'max_execution_time=3600'; \
    echo 'max_input_time=3600'; \
    echo 'default_socket_timeout=3600'; \
    echo 'memory_limit=1G'; \
    echo 'display_errors=Off'; \
    echo 'display_startup_errors=Off'; \
    echo 'log_errors=On'; \
    echo 'opcache.interned_strings_buffer=64'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.revalidate_freq=0'; \
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
