# Change Log

## 3 - centos-7-httpd24u-php72u

Summary of release changes.

### 3.3.2 - Unreleased

- Updates php-hello-world to [0.14.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.14.0).
- Updates bootstrap script to set ownership of app package binaries in the `bin/` path irrespective of `mod_fcgid` being installed.
- Adds configuration file replacement of placeholders for Xdebug's `DBGP_IDEKEY`.
- Adds PHP 5 applicable session settings into service configuration.

### 3.3.1 - 2019-07-26

- Updates php-hello-world to [0.13.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.13.0).
- Updates environment variable ordering for consistency.
- Updates screenshots in README.
- Adds setting PHP `date.timezone` to `PHP_OPTIONS_DATE_TIMEZONE` into service configuration; removes dependency on app package configuration.
- Adds session PHP settings into service configuration; removes dependency on app package configuration.
- Removes PHP 5.6 image variant from listing in README; no longer maintained.

### 3.3.0 - 2019-07-15

- Updates source image to [2.6.0](https://github.com/jdeathe/centos-ssh/releases/tag/2.6.0).
- Updates php-hello-world to [0.12.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.12.0).
- Updates `httpd24u` packages to 2.4.39-2.
- Updates `php72u` packages to 7.2.18-1.
- Updates Dockerfile `org.deathe.description` metadata LABEL to include PHP redis module.
- Updates description in centos-ssh-apache-php.register@.service.
- Updates wrapper to set httpd ErrorLog to `/dev/stderr` instead of `/dev/stdout`.
- Updates Apache configuration to use DSO Module identifiers for consistency.
- Updates CHANGELOG.md to simplify maintenance.
- Updates README.md to simplify contents and improve readability.
- Updates README-short.txt to apply to all image variants.
- Updates Dockerfile `org.deathe.description` metadata LABEL for consistency.
- Updates supervisord configuration to send error log output to stderr.
- Updates bootstrap timer to use UTC date timestamps.
- Updates bootstrap supervisord configuration file/priority to `20-httpd-bootstrap.conf`/`20`.
- Updates php-fpm wrapper supervisord configuration file/priority to `50-php-fpm-wrapper.conf`/`50`.
- Updates httpd wrapper supervisord configuration file/priority to `70-httpd-wrapper.conf`/`70`.
- Fixes bootstrap; ensure user creation occurs before setting ownership with user.
- Fixes docker host connection status check in Makefile.
- Adds `PACKAGE_PATH` placeholder/variable replacement in bootstrap of configuration files.
- Adds `inspect`, `reload` and `top` Makefile targets.
- Adds improved `clean` Makefile target; includes exited containers and dangling images.
- Adds `SYSTEM_TIMEZONE` handling to Makefile, scmi, systemd unit and docker-compose templates.
- Adds system time zone validation to healthcheck.
- Adds lock/state file to bootstrap/wrapper scripts.
- Removes unused `DOCKER_PORT_MAP_TCP_22` variable from environment includes.
- Removes support for long image tags (i.e. centos-7-httpd24u-php72u-3.x.x).
- Removes `APACHE_AUTOSTART_HTTPD_BOOTSTRAP`, replaced with `ENABLE_HTTPD_BOOTSTRAP`.
- Removes `APACHE_AUTOSTART_HTTPD_WRAPPER`, replaced with `ENABLE_HTTPD_WRAPPER`.
- Removes `APACHE_AUTOSTART_PHP_FPM_WRAPPER`, replaced with `ENABLE_PHP_FPM_WRAPPER`.

### 3.2.0 - 2019-04-11

- Updates `elinks` package to elinks-0.12-0.37.pre6.el7.0.1.
- Updates `httpd24u` packages to 2.4.39-1.
- Updates `php72u` packages to 7.2.16-1.
- Updates source image to [2.5.1](https://github.com/jdeathe/centos-ssh/releases/tag/2.5.1).
- Updates and restructures Dockerfile.
- Updates container naming conventions and readability of `Makefile`.
- Updates supervisord program priority of `php-fpm-wrapper` to a lower value than `httpd-wrapper`.
- Fixes issue with unexpected published port in run templates when `DOCKER_PORT_MAP_TCP_80`, `DOCKER_PORT_MAP_TCP_443` or `DOCKER_PORT_MAP_TCP_8443` is set to an empty string or 0.
- Fixes binary paths in systemd unit files for compatibility with both EL and Ubuntu hosts.
- Fixes link to OpenSSL ciphers manual page.
- Adds consideration for event lag into test cases for unhealthy health_status events.
- Adds port incrementation to Makefile's run template for container names with an instance suffix.
- Adds placeholder replacement of `RELEASE_VERSION` docker argument to systemd service unit template.
- Adds improvement to pull logic in systemd unit install template.
- Adds `SSH_AUTOSTART_SUPERVISOR_STDOUT` with a value "false", disabling startup of `supervisor_stdout`.
- Adds error messages to healthcheck script and includes supervisord check.
- Adds improved logging output.
- Adds images directory `.dockerignore` to reduce size of build context.
- Adds docker-compose configuration example.
- Adds improved lock/state file implementation between bootstrap and wrapper scripts.
- Adds graceful stop signals the supervisord configuration for `httpd-wrapper` and `php-fpm-wrapper`.
- Removes use of `/etc/services-config` paths.
- Removes the unused group element from the default container name.
- Removes the node element from the default container name.
- Removes unused environment variables from Makefile and scmi configuration.
- Removes X-Fleet section from etcd register template unit-file.
- Removes unnecessary configuration file `/etc/httpd-bootstrap.conf`.
- Removes systemd health reporting from PHP-FPM configuration.
- Removes unnecessarily setting random passwords for system accounts during bootstrap; lock instead.
- Removes requirement for `/usr/sbin/httpd-startup`.

### 3.1.1 - 2018-12-03

- Updates `php72u` packages to 7.2.12-1.
- Updates `httpd24u` packages to 2.4.35-1.
- Updates source image to [2.4.1](https://github.com/jdeathe/centos-ssh/releases/tag/2.4.1).
- Updates php-hello-world to [0.11.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.11.0).
- Adds improved example of `apachectl` usage via docker exec.
- Adds `php72u-pecl-redis` package to support Redis.

### 3.1.0 - 2018-09-03

- Updates `php72u` packages to 7.2.8-1.
- Updates `httpd24u` packages to 2.4.34-1.
- Updates source image to [2.4.0](https://github.com/jdeathe/centos-ssh/releases/tag/2.4.0).
- Updates php-hello-world to [0.10.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.10.0).
- Adds web fonts to expires rules.

### 3.0.1 - 2018-06-20

- Updates php-hello-world to [0.9.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.9.0).
- Removes ~20MB of image files added by the `centos-logos` package.
- Fixes links and image tag in the README documentation.

### 3.0.0 - 2018-06-15

- Initial release