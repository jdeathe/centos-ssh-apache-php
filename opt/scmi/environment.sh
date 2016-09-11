# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
DOCKER_USER=jdeathe
DOCKER_IMAGE_NAME=centos-ssh-apache-php

# Tag validation patterns
DOCKER_IMAGE_TAG_PATTERN='^(latest|(centos-[6-7])|(centos-(6-1|7-2).[0-9]+.[0-9]+))$'
DOCKER_IMAGE_RELEASE_TAG_PATTERN='^centos-(6-1|7-2).[0-9]+.[0-9]+$'

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# Docker image/container settings
DOCKER_CONTAINER_PARAMETERS_APPEND="${DOCKER_CONTAINER_PARAMETERS_APPEND:-}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-latest}"
DOCKER_NAME="${DOCKER_NAME:-apache-php.app-1.1.1}"
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-8080}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-9443}"
DOCKER_PORT_MAP_TCP_8443="${DOCKER_PORT_MAP_TCP_8443:-8580}"
DOCKER_RESTART_POLICY="${DOCKER_RESTART_POLICY:-always}"

# Docker build --no-cache parameter
NO_CACHE="${NO_CACHE:-false}"

# Directory path for release packages
PACKAGE_PATH="${PACKAGE_PATH:-./packages/jdeathe}"

# ETCD register service settings
REGISTER_ETCD_PARAMETERS="${REGISTER_ETCD_PARAMETERS:-}"
REGISTER_TTL="${REGISTER_TTL:-60}"
REGISTER_UPDATE_INTERVAL="${REGISTER_UPDATE_INTERVAL:-55}"

# -----------------------------------------------------------------------------
# Application container configuration
# -----------------------------------------------------------------------------
SSH_AUTHORIZED_KEYS="${SSH_AUTHORIZED_KEYS:-}"
SSH_AUTOSTART_SSHD="${SSH_AUTOSTART_SSHD:-true}"
SSH_AUTOSTART_SSHD_BOOTSTRAP="${SSH_AUTOSTART_SSHD_BOOTSTRAP:-true}"
SSH_CHROOT_DIRECTORY="${SSH_CHROOT_DIRECTORY:-%h}"
SSH_INHERIT_ENVIRONMENT="${SSH_INHERIT_ENVIRONMENT:-false}"
SSH_SUDO="${SSH_SUDO:-ALL=(ALL) ALL}"
SSH_USER="${SSH_USER:-app-admin}"
SSH_USER_FORCE_SFTP="${SSH_USER_FORCE_SFTP:-false}"
SSH_USER_HOME="${SSH_USER_HOME:-/home/%u}"
SSH_USER_ID="${SSH_USER_ID:-500:500}"
SSH_USER_PASSWORD="${SSH_USER_PASSWORD:-}"
SSH_USER_PASSWORD_HASHED="${SSH_USER_PASSWORD_HASHED:-false}"
SSH_USER_SHELL="${SSH_USER_SHELL:-/bin/bash}"
# -----------------------------------------------------------------------------
APACHE_CONTENT_ROOT="${APACHE_CONTENT_ROOT:-/var/www/app}"
APACHE_CUSTOM_LOG_FORMAT="${APACHE_CUSTOM_LOG_FORMAT:-combined}"
APACHE_CUSTOM_LOG_LOCATION="${APACHE_CUSTOM_LOG_LOCATION:-${APACHE_CONTENT_ROOT}/var/log/apache_access_log}"
APACHE_ERROR_LOG_LOCATION="${APACHE_ERROR_LOG_LOCATION:-${APACHE_CONTENT_ROOT}/var/log/apache_error_log}"
APACHE_ERROR_LOG_LEVEL="${APACHE_ERROR_LOG_LEVEL:-warn}"
APACHE_EXTENDED_STATUS_ENABLED="${APACHE_EXTENDED_STATUS_ENABLED:-false}"
APACHE_HEADER_X_SERVICE_UID="${APACHE_HEADER_X_SERVICE_UID:-{{HOSTNAME}}}"
APACHE_LOAD_MODULES="${APACHE_LOAD_MODULES:-authz_user_module log_config_module expires_module deflate_module headers_module setenvif_module mime_module status_module dir_module alias_module}"
APACHE_OPERATING_MODE="${APACHE_OPERATING_MODE:-production}"
APACHE_MOD_SSL_ENABLED="${APACHE_MOD_SSL_ENABLED:-false}"
APACHE_MPM="${APACHE_MPM:-prefork}"
APACHE_PUBLIC_DIRECTORY="${APACHE_PUBLIC_DIRECTORY:-public_html}"
APACHE_RUN_GROUP="${APACHE_RUN_GROUP:-app-www}"
APACHE_RUN_USER="${APACHE_RUN_USER:-app-www}"
APACHE_SERVER_ALIAS="${APACHE_SERVER_ALIAS:-app-1}"
APACHE_SERVER_NAME="${APACHE_SERVER_NAME:-app-1.local}"
APACHE_SYSTEM_USER="${APACHE_SYSTEM_USER:-app}"
PHP_OPTIONS_DATE_TIMEZONE="${PHP_OPTIONS_DATE_TIMEZONE:-UTC}"
