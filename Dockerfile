FROM dunglas/frankenphp:1.12.1-php8-alpine

RUN curl -o wordpress.tar.gz https://wordpress.org/wordpress-6.9.4.tar.gz \
    && tar -xzf wordpress.tar.gz -C /var/www/html --strip-components=1 \
    && rm wordpress.tar.gz


RUN install-php-extensions \
    pdo_mysql \
    gd \
    intl \
    zip \
    opcache \
    redis \
    mysqli

WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["frankenphp","php-server"]