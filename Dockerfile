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

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Expose HTTP port
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["frankenphp", "php-server"]