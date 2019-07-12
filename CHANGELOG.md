# Change Log

## 2 - centos-6-httpd24u-php56u

Summary of release changes.

### 2.5.0 - Unreleased

- Updates Dockerfile `org.deathe.description` metadata LABEL to include PHP redis module.
- Updates description in centos-ssh-apache-php.register@.service.
- Updates wrapper to set httpd ErrorLog to `/dev/stderr` instead of `/dev/stdout`.
- Updates Apache configuration to use DSO Module identifiers for consistency.
- Updates CHANGELOG.md to simplify maintenance.
- Updates README.md to simplify contents and improve readability.
- Updates README-short.txt to apply to all image variants.
- Updates Dockerfile `org.deathe.description` metadata LABEL for consistency.
- Fixes README SSL/TLS data volume names/paths in examples.
- Fixes bootstrap; ensure user creation occurs before setting ownership with user.
- Adds `PACKAGE_PATH` placeholder/variable replacement in bootstrap of configuration files.
- Removes unused `DOCKER_PORT_MAP_TCP_22` variable from environment includes.

### 2.4.0 - 2019-04-11

- Updates `httpd24u` packages to 2.4.39-1.
- Updates `php56u` packages to 5.6.40-1.
- Updates source image to [1.10.1](https://github.com/jdeathe/centos-ssh/releases/tag/1.10.1).
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
- Removes unnecessarily setting random passwords for system accounts during bootstrap; lock instead.
- Removes requirement for `/usr/sbin/httpd-startup`.

### 2.3.1 - 2018-12-03

- Updates `php56u` packages to 5.6.38-1.
- Updates `httpd24u` packages to 2.4.35-1.
- Updates source image to [1.9.1](https://github.com/jdeathe/centos-ssh/releases/tag/1.9.1).
- Updates php-hello-world to [0.11.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.11.0).
- Adds improved example of `apachectl` usage via docker exec.
- Adds `php56u-pecl-redis` package to support Redis.

### 2.3.0 - 2018-09-03

- Updates `php56u` packages to 5.6.37-1.
- Updates `httpd24u` packages to 2.4.34-1.
- Updates source image to [1.9.0](https://github.com/jdeathe/centos-ssh/releases/tag/1.9.0).
- Updates php-hello-world to [0.10.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.10.0).
- Adds web fonts to expires rules.

### 2.2.6 - 2018-06-20

- Updates php-hello-world to [0.9.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.9.0).

### 2.2.5 - 2018-05-20

- Updates `httpd24u` packages to 2.4.33-3.
- Updates `php56u` packages to 5.6.36-1.
- Updates source image to [1.8.4 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.4).
- Adds feature to set `APACHE_SSL_CERTIFICATE` via a file path. e.g. Docker Swarm secrets.
- Updates php-hello-world to [0.8.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.8.0).
- Adds feature to allow `PHP_OPTIONS_SESSION_SAVE_PATH` to be set relative to `APACHE_CONTENT_ROOT` for the files handler.
- Adds method of setting additional modules with `APACHE_LOAD_MODULES`.

### 2.2.4 - 2018-01-27

- Fixes issue with unusable healthcheck error messages.
- Adds correction to README.md example for usage of `APACHE_ERROR_LOG_LOCATION` and `APACHE_ERROR_LOG_LEVEL`.
- Fixes issue with environment variables not getting replaced within PHP files in the default scan directory when a app package is installed that contains no custom PHP drop-in configuration files.
- Fixes prerequisite test when testing disable wrapper features.
- Adds exclusion of internal "Docker-Healthcheck" requests from the access log.
- Adds configuration to enable Apache OCSP Stapling with a CA signed certificate.

### 2.2.3 - 2018-01-16

- Updates `php56u` packages to 5.6.33-1.
- Updates source image to [1.8.3 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.3).
- Updates php-hello-world to [0.6.0](https://github.com/jdeathe/php-hello-world/releases/tag/0.6.0).
- Adds correction to usage instructions for `APACHE_LOAD_MODULES`; the required modules were incorrect in the example.
- Adds `PHP_OPTIONS_SESSION_NAME` to optionally set PHP session.name.
- Deprecates use of the fleet `--manager` option in the `scmi` installer.

### 2.2.2 - 2017-12-25

- Updates `php56u` packages to 5.6.32-2.
- Updates `httpd24u` packages to 2.4.29-1.
- Adds a .dockerignore file.
- Adds httpoxy mitigation.

### 2.2.1 - 2017-09-28

- Updates `php56u` packages to 5.6.31-1.
- Fixes bootstrap lockfile name to match the one expected by the healthcheck.
- Adds permissions to restrict access to the healthcheck script.
- Removes scmi; it's maintained [upstream](https://github.com/jdeathe/centos-ssh/blob/centos-6/src/usr/sbin/scmi).
- Fixes local port value in scmi install template.
- Adds use of readonly variables for constants.
- Adds support for event server MPM in bootstrap.
- Adds server mpm to the Apache Details logs output.
- Adds `APACHE_AUTOSTART_HTTPD_BOOTSTRAP` to optionally disable httpd bootstrap.
- Adds `APACHE_AUTOSTART_HTTPD_WRAPPER` to optionally disable httpd process startup.
- Adds `APACHE_AUTOSTART_PHP_FPM_WRAPPER` to optionally disable PHP-FPM process startup.
- Adds `PHP_OPTIONS_SESSION_SAVE_HANDLER` to allow for an external session store.
- Adds `PHP_OPTIONS_SESSION_SAVE_PATH` to allow for an external session store.
- Updates source image to [1.8.2 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.2).

### 2.2.0 - 2017-07-13

- Adds updated `httpd24u` and `php56u` packages to 2.4.27-1 and 5.6.30-2.
- Adds improvement to VirtualHost pattern match used to disable default SSL.
- Replaces deprecated Dockerfile `MAINTAINER` with a `LABEL`.
- Update source image to [1.8.1 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.1).
- Adds a `src` directory for the image root files.
- Adds `STARTUP_TIME` variable for the `logs-delayed` Makefile target.
- Adds use of `/var/lock/subsys/` (subsystem lock directory) for bootstrap lock files.
- Adds test case output with improved readability.
- Adds a healthcheck.
- Removes healthcheck from functional tests of access log to prevent intermittent failures.
- Fixes issue with local readonly variables being writable.
- Adds simplified port incrementation handling to systemd unit and make consistent with SCMI.
- Adds configuration include directory (`conf.virtualhost.d/*.conf`) for VirtualHost partials.
- Adds configuration for setting RewriteEngine on if the module is loaded.
- Adds PHP configuration change; Opcache is enabled for the CLI.
- Adds PHP configuration change; File changes will not invalidate opcache.
- Adds PHP configuration change; Increased size and TTL of realpath_cache.

### 2.1.1 - 2017-03-12

- Adds updated `httpd24u` packages to 2.4.25-3.
- Adds updated source image to [1.7.6 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.7.6).

### 2.1.0 - 2017-02-07

- Fixes issue with app specific `httpd` configuration requiring the `etc/php.d` directory to exist.
- Fixes `shpec` test definition to allow tests to be interruptible + ports back some minor improvements made to the tests for the fcgid version.
- Adds default Apache modules appropriate for Apache 2.4/2.2 in the bootstrap script for the unlikely case where the values in the environment and configuration file defaults are both unset.
- Updates `README.md` with details of the SCMI install example's prerequisite step of either pulling or loading the image.
- Updates package versions for `httpd24u` and `php56u` + define specific versions in the Dockerfile.
- Fixes issue with `ssl_module` being loaded when `APACHE_MOD_SSL_ENABLED` was set to `false`.
- Fixes noisy certificate generation output in logs during bootstrap when `APACHE_MOD_SSL_ENABLED` is `true`.
- Changes `APACHE_SERVER_ALIAS` to a default empty value for `Makefile`, `scmi` and `systemd` templates which is the existing `Dockerfile` default.
- Changes description of app to include "PHP-FPM (FastCGI)" instead of "PHP (PHP-FPM)".
- Changes default `APACHE_SERVER_NAME` to unset and use the container's hostname for the Apache ServerName.
- Fixes `scmi` install/uninstall examples and Dockerfile `LABEL` install/uninstall templates to prevent the `X-Service-UID` header being populated with the hostname of the ephemeral container used to run `scmi`.
- Adds feature to allow both `APACHE_SERVER_NAME` and `APACHE_SERVER_ALIAS` to contain the `{{HOSTNAME}}` placeholder which is replaced on startup with the container's hostname.
- Removes environment variable re-mappings that are no longer in use: `APP_HOME_DIR`, `APACHE_SUEXEC_USER_GROUP`, `DATE_TIMEZONE`, `SERVICE_USER`, `SUEXECUSERGROUP`, `SERVICE_UID`.
- Changes Apache configuration so that `NameVirtualHost` and `Listen` are separated out from `VirtualHost`.
- Adds further information on the use of `watch` to monitor `server-status`.
- Changes the auto-generated self-signed certificate to include hosts from `APACHE_SERVER_NAME` and `APACHE_SERVER_ALIAS` via subjectAltName.

### 2.0.1 - 2017-01-24

- Replaces `mv` operations with `cat` to work-around OverlayFS limitations in CentOS-7.
- Removes unwanted trailing backslash characters from `opt/scmi/environment.sh`.
- Adds updated source image to [1.7.5 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.7.5).
- Adds reduced number of image layers.
- Adds a Change Log.
- Adds support for semantic version numbered tags.
- Adds minor code style changes to the Makefile.
- Adds test cases using [shpec](https://github.com/rylnd/shpec), run with `make test`.
- Set the Apache run group to the group defined in `APACHE_RUN_GROUP`.
- Adds ExtendedStatus is `Off` by default.

### 2.0.0 - 2016-10-27

- Initial release