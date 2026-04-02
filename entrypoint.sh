#!/bin/sh
set -e

WP_CONFIG="/var/www/html/wp-config.php"

# Always regenerate wp-config.php from sample so env vars are always applied
cp /var/www/html/wp-config-sample.php "$WP_CONFIG"

# Helper: replace define if it exists, otherwise insert before wp-settings.php require
set_define() {
    key="$1"
    value="$2"
    if grep -q "define[( ]*'${key}'" "$WP_CONFIG"; then
        sed -i "s|define[( ]*'${key}'[^;]*);|define( '${key}', ${value} );|" "$WP_CONFIG"
    else
        sed -i "s|require_once ABSPATH . 'wp-settings.php';|define( '${key}', ${value} );\nrequire_once ABSPATH . 'wp-settings.php';|" "$WP_CONFIG"
    fi
}

# DB / core settings (these exist in the sample, sed replaces them)
# DB_HOST supports host:port format for non-standard ports (e.g. 91.98.44.142:3331)
[ -n "$WORDPRESS_DB_HOST" ]     && sed -i "s|define( 'DB_HOST',.*);|define( 'DB_HOST', '${WORDPRESS_DB_HOST}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DB_NAME" ]     && sed -i "s|define( 'DB_NAME',.*);|define( 'DB_NAME', '${WORDPRESS_DB_NAME}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DB_USER" ]     && sed -i "s|define( 'DB_USER',.*);|define( 'DB_USER', '${WORDPRESS_DB_USER}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DB_PASSWORD" ] && sed -i "s|define( 'DB_PASSWORD',.*);|define( 'DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DEBUG" ]       && sed -i "s|define( 'WP_DEBUG',.*);|define( 'WP_DEBUG', ${WORDPRESS_DEBUG} );|" "$WP_CONFIG"

# SSL / HTTPS behind reverse proxy
set_define 'FORCE_SSL_ADMIN' "true"
grep -q "\$_SERVER\['HTTPS'\]" "$WP_CONFIG" || \
    sed -i "s|require_once ABSPATH . 'wp-settings.php';|\$_SERVER['HTTPS'] = 'on';\nrequire_once ABSPATH . 'wp-settings.php';|" "$WP_CONFIG"
grep -q "\$_SERVER\['HTTP_X_FORWARDED_PROTO'\]" "$WP_CONFIG" || \
    sed -i "s|require_once ABSPATH . 'wp-settings.php';|\$_SERVER['HTTP_X_FORWARDED_PROTO'] = 'https';\nrequire_once ABSPATH . 'wp-settings.php';|" "$WP_CONFIG"

# Site URL — prevents mixed content on fresh install (set WORDPRESS_HOME to https://yourdomain)
[ -n "$WORDPRESS_HOME" ]    && set_define 'WP_HOME'    "'${WORDPRESS_HOME}'"
[ -n "$WORDPRESS_SITEURL" ] && set_define 'WP_SITEURL' "'${WORDPRESS_SITEURL}'"

# Performance / upload limits
set_define 'WP_MEMORY_LIMIT'    "'${WP_MEMORY_LIMIT:-1G}'"
set_define 'DISALLOW_FILE_EDIT' "${DISALLOW_FILE_EDIT:-true}"
set_define 'WP_MAX_UPLOAD_SIZE' "${WP_MAX_UPLOAD_SIZE:-5368709120}"

# Redis
set_define 'WP_REDIS_SCHEME'   "'${WP_REDIS_SCHEME:-tcp}'"
set_define 'WP_REDIS_HOST'     "'${WP_REDIS_HOST:-localhost}'"
set_define 'WP_REDIS_PORT'     "${WP_REDIS_PORT:-6379}"
set_define 'WP_REDIS_USER'     "'${WP_REDIS_USER:-default}'"
set_define 'WP_REDIS_PASSWORD' "'${WP_REDIS_PASSWORD:-non}'"
set_define 'WP_REDIS_DB'       "${WP_REDIS_DB:-0}"
set_define 'WP_REDIS_PREFIX'   "'${WP_REDIS_PREFIX:-site:}'"

# Millicache (MC_STORAGE_* — falls back to Redis vars)
set_define 'WP_CACHE' "${WP_CACHE:-true}"
set_define 'MC_STORAGE_HOST'     "'${MC_STORAGE_HOST:-${WP_REDIS_HOST:-127.0.0.1}}'"
set_define 'MC_STORAGE_PORT'     "${MC_STORAGE_PORT:-${WP_REDIS_PORT:-6379}}"
set_define 'MC_STORAGE_PASSWORD' "'${MC_STORAGE_PASSWORD:-${WP_REDIS_PASSWORD:-}}'"
set_define 'MC_STORAGE_DB'       "${MC_STORAGE_DB:-${WP_REDIS_DB:-0}}"
set_define 'MC_STORAGE_PREFIX'   "'${MC_STORAGE_PREFIX:-${WP_REDIS_PREFIX:-mll}}'"

# PHP runtime overrides — insert before wp-settings.php if not already present
for ini_line in \
    "@ini_set('upload_max_filesize', '${PHP_UPLOAD_MAX_FILESIZE:-5G}');" \
    "@ini_set('post_max_size', '${PHP_POST_MAX_SIZE:-5G}');" \
    "@ini_set('max_execution_time', '${PHP_MAX_EXECUTION_TIME:-300}');" \
    "@ini_set('max_input_time', '${PHP_MAX_INPUT_TIME:-300}');"; do
    key=$(echo "$ini_line" | grep -o "'[^']*'" | head -1)
    grep -q "$key" "$WP_CONFIG" || \
        sed -i "s|require_once ABSPATH . 'wp-settings.php';|${ini_line}\nrequire_once ABSPATH . 'wp-settings.php';|" "$WP_CONFIG"
done

# Append extra config from environment variable
if [ -n "$WORDPRESS_CONFIG_EXTRA" ]; then
    echo "" >> "$WP_CONFIG"
    echo "// Extra config from WORDPRESS_CONFIG_EXTRA" >> "$WP_CONFIG"
    echo "$WORDPRESS_CONFIG_EXTRA" >> "$WP_CONFIG"
fi

# Execute the main command
exec "$@"