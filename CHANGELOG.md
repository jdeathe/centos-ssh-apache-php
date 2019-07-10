# Change Log

## centos-7-httpd24u-php72u

Summary of release changes for Version 3.

CentOS-7 7.5.1804 x86_64, Apache 2.4, PHP-FPM 7.2, PHP memcached 3.0, Zend Opcache 7.2.

### 3.3.0 - Unreleased

- Updates `php72u` packages to 7.2.18-1.
- Updates Dockerfile `org.deathe.description` metadata LABEL to include PHP redis module.
- Updates description in centos-ssh-apache-php.register@.service.
- Updates wrapper to set httpd ErrorLog to `/dev/stderr` instead of `/dev/stdout`.
- Fixes bootstrap; ensure user creation occurs before setting ownership with user.
- Removes unused `DOCKER_PORT_MAP_TCP_22` variable from environment includes.

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