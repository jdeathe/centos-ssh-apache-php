# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
readonly DOCKER_IMAGE_NAME=centos-ssh-apache-php
readonly DOCKER_IMAGE_RELEASE_TAG_PATTERN='^[1-3]\.[0-9]+\.[0-9]+$'
readonly DOCKER_IMAGE_TAG_PATTERN='^(latest|[1-3]\.[0-9]+\.[0-9]+)$'
readonly DOCKER_USER=jdeathe
readonly SHPEC_ROOT=test/shpec

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
DIST_PATH="${DIST_PATH:-./dist}"
DOCKER_CONTAINER_OPTS="${DOCKER_CONTAINER_OPTS:-}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-latest}"
DOCKER_NAME="${DOCKER_NAME:-apache-php.1}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-8080}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-9443}"
DOCKER_PORT_MAP_TCP_8443="${DOCKER_PORT_MAP_TCP_8443:-NULL}"
DOCKER_RESTART_POLICY="${DOCKER_RESTART_POLICY:-always}"
NO_CACHE="${NO_CACHE:-false}"
REGISTER_ETCD_PARAMETERS="${REGISTER_ETCD_PARAMETERS:-}"
REGISTER_TTL="${REGISTER_TTL:-60}"
REGISTER_UPDATE_INTERVAL="${REGISTER_UPDATE_INTERVAL:-55}"
STARTUP_TIME="${STARTUP_TIME:-2}"

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
APACHE_CONTENT_ROOT="${APACHE_CONTENT_ROOT:-/var/www/app}"
APACHE_CUSTOM_LOG_FORMAT="${APACHE_CUSTOM_LOG_FORMAT:-combined}"
APACHE_CUSTOM_LOG_LOCATION="${APACHE_CUSTOM_LOG_LOCATION:-var/log/apache_access_log}"
APACHE_ERROR_LOG_LOCATION="${APACHE_ERROR_LOG_LOCATION:-var/log/apache_error_log}"
APACHE_ERROR_LOG_LEVEL="${APACHE_ERROR_LOG_LEVEL:-warn}"
APACHE_EXTENDED_STATUS_ENABLED="${APACHE_EXTENDED_STATUS_ENABLED:-false}"
APACHE_HEADER_X_SERVICE_UID="${APACHE_HEADER_X_SERVICE_UID:-"{{HOSTNAME}}"}"
APACHE_LOAD_MODULES="${APACHE_LOAD_MODULES:-}"
APACHE_OPERATING_MODE="${APACHE_OPERATING_MODE:-production}"
APACHE_MOD_SSL_ENABLED="${APACHE_MOD_SSL_ENABLED:-false}"
APACHE_MPM="${APACHE_MPM:-prefork}"
APACHE_PUBLIC_DIRECTORY="${APACHE_PUBLIC_DIRECTORY:-public_html}"
APACHE_RUN_GROUP="${APACHE_RUN_GROUP:-app-www}"
APACHE_RUN_USER="${APACHE_RUN_USER:-app-www}"
APACHE_SERVER_ALIAS="${APACHE_SERVER_ALIAS:-}"
APACHE_SERVER_NAME="${APACHE_SERVER_NAME:-}"
APACHE_SSL_CERTIFICATE="${APACHE_SSL_CERTIFICATE:-}"
APACHE_SSL_CIPHER_SUITE="${APACHE_SSL_CIPHER_SUITE:-"ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"}"
APACHE_SSL_PROTOCOL="${APACHE_SSL_PROTOCOL:-"All -SSLv2 -SSLv3"}"
APACHE_SYSTEM_USER="${APACHE_SYSTEM_USER:-app}"
ENABLE_HTTPD_BOOTSTRAP="${ENABLE_HTTPD_BOOTSTRAP:-true}"
ENABLE_HTTPD_WRAPPER="${ENABLE_HTTPD_WRAPPER:-true}"
PHP_OPTIONS_DATE_TIMEZONE="${PHP_OPTIONS_DATE_TIMEZONE:-UTC}"
PHP_OPTIONS_SESSION_NAME="${PHP_OPTIONS_SESSION_NAME:-PHPSESSID}"
PHP_OPTIONS_SESSION_SAVE_HANDLER="${PHP_OPTIONS_SESSION_SAVE_HANDLER:-files}"
PHP_OPTIONS_SESSION_SAVE_PATH="${PHP_OPTIONS_SESSION_SAVE_PATH:-var/session}"
SYSTEM_TIMEZONE="${SYSTEM_TIMEZONE:-UTC}"
