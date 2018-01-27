# Change Log

## centos-6-httpd24u-php56u

Summary of release changes for Version 2.

CentOS-6 6.9 x86_64, Apache 2.4, PHP-FPM 5.6, PHP memcached 2.2, Zend Opcache 7.0.

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