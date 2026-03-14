#!/bin/sh
set -e

WP_CONFIG="/var/www/html/wp-config.php"

# Always regenerate wp-config.php from sample so env vars are always applied
cp /var/www/html/wp-config-sample.php "$WP_CONFIG"

# Helper: replace define if it exists, otherwise append it
set_define() {
    key="$1"
    value="$2"
    if grep -q "define[( ]*'${key}'" "$WP_CONFIG"; then
        sed -i "s|define[( ]*'${key}'[^;]*);|define( '${key}', ${value} );|" "$WP_CONFIG"
    else
        echo "define( '${key}', ${value} );" >> "$WP_CONFIG"
    fi
}

# DB / core settings (these exist in the sample, sed replaces them)
# DB_HOST supports host:port format for non-standard ports (e.g. 91.98.44.142:3331)
[ -n "$WORDPRESS_DB_HOST" ]     && sed -i "s|define( 'DB_HOST',.*);|define( 'DB_HOST', '${WORDPRESS_DB_HOST}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DB_NAME" ]     && sed -i "s|define( 'DB_NAME',.*);|define( 'DB_NAME', '${WORDPRESS_DB_NAME}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DB_USER" ]     && sed -i "s|define( 'DB_USER',.*);|define( 'DB_USER', '${WORDPRESS_DB_USER}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DB_PASSWORD" ] && sed -i "s|define( 'DB_PASSWORD',.*);|define( 'DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}' );|" "$WP_CONFIG"
[ -n "$WORDPRESS_DEBUG" ]       && sed -i "s|define( 'WP_DEBUG',.*);|define( 'WP_DEBUG', ${WORDPRESS_DEBUG} );|" "$WP_CONFIG"

# Performance / upload limits
set_define 'WP_MEMORY_LIMIT'    "'${WP_MEMORY_LIMIT:-1G}'"
set_define 'DISALLOW_FILE_EDIT' "${DISALLOW_FILE_EDIT:-true}"
set_define 'WP_MAX_UPLOAD_SIZE' "${WP_MAX_UPLOAD_SIZE:-5368709120}"

# Redis
set_define 'WP_REDIS_SCHEME'   "'${WP_REDIS_SCHEME:-tcp}'"
set_define 'WP_REDIS_HOST'     "'${WP_REDIS_HOST:-fisio-cache-47drru}'"
set_define 'WP_REDIS_PORT'     "${WP_REDIS_PORT:-6379}"
set_define 'WP_REDIS_USER'     "'${WP_REDIS_USER:-default}'"
set_define 'WP_REDIS_PASSWORD' "'${WP_REDIS_PASSWORD:-uhoiWUOnA3c6HCZKGdj1}'"
set_define 'WP_REDIS_DB'       "${WP_REDIS_DB:-0}"
set_define 'WP_REDIS_PREFIX'   "'${WP_REDIS_PREFIX:-fisio:}'"

# PHP runtime overrides
grep -q "upload_max_filesize" "$WP_CONFIG" || echo "@ini_set('upload_max_filesize', '${PHP_UPLOAD_MAX_FILESIZE:-5G}');" >> "$WP_CONFIG"
grep -q "post_max_size"       "$WP_CONFIG" || echo "@ini_set('post_max_size', '${PHP_POST_MAX_SIZE:-5G}');"             >> "$WP_CONFIG"
grep -q "max_execution_time"  "$WP_CONFIG" || echo "@ini_set('max_execution_time', '${PHP_MAX_EXECUTION_TIME:-300}');" >> "$WP_CONFIG"
grep -q "max_input_time"      "$WP_CONFIG" || echo "@ini_set('max_input_time', '${PHP_MAX_INPUT_TIME:-300}');"         >> "$WP_CONFIG"

# Append extra config from environment variable
if [ -n "$WORDPRESS_CONFIG_EXTRA" ]; then
    echo "" >> "$WP_CONFIG"
    echo "// Extra config from WORDPRESS_CONFIG_EXTRA" >> "$WP_CONFIG"
    echo "$WORDPRESS_CONFIG_EXTRA" >> "$WP_CONFIG"
fi

# Execute the main command
exec "$@"