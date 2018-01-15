# Change Log

## centos-6

Summary of release changes for Version 1.

CentOS-6 6.9 x86_64, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1.

### 1.10.3 - Unreleased

- Updates source image to [1.8.3 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.3).

### 1.10.2 - 2017-12-25

- Updates `httpd` and `mod_ssl` packages to 2.2.15-60.
- Adds a .dockerignore file.
- Adds httpoxy mitigation.

### 1.10.1 - 2017-09-28

- Fixes bootstrap lockfile name to match the one expected by the healthcheck.
- Adds permissions to restrict access to the healthcheck script.
- Removes scmi; it's maintained [upstream](https://github.com/jdeathe/centos-ssh/blob/centos-6/src/usr/sbin/scmi).
- Fixes local port value in scmi install template.
- Adds use of readonly variables for constants.
- Adds support for event server MPM in bootstrap.
- Adds server mpm to the Apache Details logs output.
- Adds `APACHE_AUTOSTART_HTTPD_BOOTSTRAP` to optionally disable httpd bootstrap.
- Adds `APACHE_AUTOSTART_HTTPD_WRAPPER` to optionally disable httpd process startup.
- Adds `PHP_OPTIONS_SESSION_SAVE_HANDLER` to allow for an external session store.
- Adds `PHP_OPTIONS_SESSION_SAVE_PATH` to allow for an external session store.
- Updates source image to [1.8.2 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.8.2).

### 1.10.0 - 2017-07-13

- Adds updated packages `httpd` (including `mod_ssl`) and `php` to 2.2.15-59 and 5.3.3-49.
- Adds improvement to VirtualHost pattern match used to disable default SSL.
- Replaces deprecated Dockerfile `MAINTAINER` with a `LABEL`.
- Adds improvement to the sed pattern match for `php_uname('n');` that was causing syntax highlighting issues.
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
- Adds PHP configuration change; ACP opcache is enabled for the CLI.
- Adds PHP configuration change; File changes will not invalidate APC opcache.
- Adds PHP configuration change; Disables APC file update protection.
- Adds PHP configuration change; Increased size and TTL of realpath_cache.

### 1.9.1 - 2017-03-12

- Adds updated source image to [1.7.6 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.7.6).

### 1.9.0 - 2017-02-07

- Fixes issue with app specific `httpd` configuration requiring the `etc/php.d` directory to exist.
- Fixes `shpec` test definition to allow tests to be interruptible + ports back some minor improvements made to the tests for the fcgid version.
- Adds default Apache modules appropriate for Apache 2.4/2.2 in the bootstrap script for the unlikely case where the values in the environment and configuration file defaults are both unset.
- Updates `README.md` with details of the SCMI install example's prerequisite step of either pulling or loading the image.
- Updates `httpd` and `mod_ssl` packages.
- Fixes noisy certificate generation output in logs during bootstrap when `APACHE_MOD_SSL_ENABLED` is `true`.
- Changes `APACHE_SERVER_ALIAS` to a default empty value for `Makefile`, `scmi` and `systemd` templates which is the existing `Dockerfile` default.
- Changes default `APACHE_SERVER_NAME` to unset and use the container's hostname for the Apache ServerName.
- Fixes `scmi` install/uninstall examples and Dockerfile `LABEL` install/uninstall templates to prevent the `X-Service-UID` header being populated with the hostname of the ephemeral container used to run `scmi`.
- Adds feature to allow both `APACHE_SERVER_NAME` and `APACHE_SERVER_ALIAS` to contain the `{{HOSTNAME}}` placeholder which is replaced on startup with the container's hostname.
- Removes environment variable re-mappings that are no longer in use: `APP_HOME_DIR`, `APACHE_SUEXEC_USER_GROUP`, `DATE_TIMEZONE`, `SERVICE_USER`, `SUEXECUSERGROUP`, `SERVICE_UID`.
- Changes Apache configuration so that `NameVirtualHost` and `Listen` are separated out from `VirtualHost`.
- Adds further information on the use of `watch` to monitor `server-status`.
- Changes the auto-generated self-signed certificate to include hosts from `APACHE_SERVER_NAME` and `APACHE_SERVER_ALIAS` via subjectAltName.

### 1.8.2 - 2017-01-24

- Replaces `mv` operations with `cat` to work-around OverlayFS limitations in CentOS-7.
- Adds updated source image to [1.7.5 tag](https://github.com/jdeathe/centos-ssh/releases/tag/1.7.5).
- Adds reduced number of image layers.
- Adds a Change Log.
- Adds support for semantic version numbered tags.
- Adds minor code style changes to the Makefile.
- Adds test cases using [shpec](https://github.com/rylnd/shpec), run with `make test`.
- Set the Apache run group to the group defined in `APACHE_RUN_GROUP`.
- Adds `version_module` as a default loaded module.

### 1.8.1 - 2016-10-27

- Adds updated README with details of new 2.0.0 release tag.
- Adds updated image tag pattern rules required for the new `centos-6-httpd24u-php56u` based tags.

### 1.8.0 - 2016-10-25

- Adds installation of php-hello-world app from [external release source](https://github.com/jdeathe/php-hello-world/releases).
- Adds UseCanonicalName On httpd setting.
- Adds reduced Dockerfile build layers for installing PHP app package.
- Adds startup script `/usr/sbin/httpd-startup` used to initialise environment variables; paths that are relative are expanded to absolute and the hostname placeholder is replaced with the container's hostname. This logic has been moved out of the Apache wrapper script so it can be set globally and made available when accessing the container interactively.
- Adds package php-hello-world 0.4.0.
- Adds update browser screenshots to documentation.

### 1.7.3 - 2016-10-02

- Adds Makefile help target with usage instructions.
- Splits up the Makefile targets into internal and public types.
- Adds correct `scmi` path in usage instructions.
- Changes `PACKAGE_PATH` to `DIST_PATH` in line with the Makefile environment include. Not currently used by `scmi` but changing for consistency.
- Changes `DOCKER_CONTAINER_PARAMETERS_APPEND` to `DOCKER_CONTAINER_OPTS` for usability. This is a potentially breaking change that could affect systemd service configurations if using the Environment variable in a drop-in customisation. However, if using the systemd template unit-files it should be pinned to a specific version tag. The Makefile should only be used for development/testing and usage in `scmi` is internal only as the `--setopt` parameter is used to build up the optional container parameters. 
- Removes X-Fleet section from template unit-file.

### 1.7.2 - 2016-09-30

- Updates source to release centos-6-1.7.2.
- Replaces `PACKAGE_PATH` with `DIST_PATH` in Makefile. The package output directory created will be `./dist` instead of `./packages/jdeathe`.
- Apache VirtualHost configuration has been simplified to only require a single certificate bundle file (`/etc/pki/tls/certs/localhost.crt`) in PEM format.
- Adds `APACHE_SSL_CERTIFICATE` to allow the operator to add a PEM, (and optionally base64), encoded certificate bundle (inclusive of key + certificate + intermediate certificate. Base64 encoding of the PEM file contents is recommended.
- Adds `APACHE_SSL_CIPHER_SUITE` to allow the operator to define a custom CipherSuite.
- Adds `APACHE_SSL_PROTOCOL` to allow the operator to add/remove SSL protocol support.
- Adds usage instructions for `APACHE_SSL_CERTIFICATE`, `APACHE_SSL_CIPHER_SUITE` and `APACHE_SSL_PROTOCOL`.
- Removes requirement to pass php package name to the php-wrapper - feature was undocumented and unused.
- Removes MySQL legacy-linked environment variable population and handling.
- Adds correct path to `scmi` in image metadata to allow `atomic install` to complete successfully.

#### Known Issues

The Makefile install (create) target fails when a `APACHE_SSL_CERTIFICATE` is set as multiline formatted string in the environment as follows.

```
$ export APACHE_SSL_CERTIFICATE="$(
  < "/etc/pki/tls/certs/localhost.crt"
)"
```

The recommended way to set the certificate value is to base64 encode it as a string value.

Mac OSX:

```
$ export APACHE_SSL_CERTIFICATE="$(
  base64 -i "/etc/pki/tls/certs/localhost.crt"
)"
```

Linux:

```
$ export APACHE_SSL_CERTIFICATE="$(
  base64 -w 0 -i "/etc/pki/tls/certs/localhost.crt"
)"
```

### 1.7.1 - 2016-09-14

- Adds scmi configuration + systemd template unit-files to image.
- Removes unnecessary step to re-add scmi to the image.
- Removes unused create/run template used by the Makefile.
- Updated README with some minor corrections and changes for consistency.

### 1.7.0 - 2016-09-13

- Updates upstream source to centos-6.1.7.0.
- Adds `scmi` and metadata for atomic install/uninstall usage.
- Removes deprecated run.sh and build.sh helper scripts. These have been replaced with the make targets `make` (or `make build`) and `make install start`.
- Removes support for and documentation on configuration volumes. These can still be implemented by making use of the `DOCKER_CONTAINER_PARAMETERS_APPEND` environment variable or using the `scmi` option `--setopt` to append additional docker parameters to the default docker create template.
- Changes systemd template unit-file environment variable for `DOCKER_IMAGE_PACKAGE_PATH` now defaults to the path `/var/opt/scmi/packages` instead of `/var/services-packages` however this can be reverted back using the `scmi` option `--env='DOCKER_IMAGE_PACKAGE_PATH="/var/services-packages"'` if necessary.
- Replaces `HTTPD` with `APACHE_MPM`; instead of needing to supply the path to the correct binary `APACHE_MPM` takes the Apache MPM name (i.e. `prefork` or `worker`).
- Replaces `SERVICE_UID` with `APACHE_HEADER_X_SERVICE_UID`.
- Default to using the `{{HOSTNAME}}` placeholder for the value of `APACHE_HEADER_X_SERVICE_UID`.
- Adds the `/usr/sbin/httpd-wrapper` script to make the wrapper more robust and simpler to maintain that the one-liner that was added directly using the supervisord program command.
- Adds Lockfile handling into the `/usr/sbin/httpd-bootstrap` script making it more robust and simpler to maintain.
- Adds a minor correction to a couple of the README `scmi` examples.
- Reviewed quoting of environment variables used in Apache include templates and in the bootstrap script.
- To be consistent with other `jdeathe/centos-ssh` based containers the default group used in the docker name has been changed to `pool-1` from `app-1`.
- Adds a niceness value of 10 to the httpd process in the httpd-wrapper script.
- Stops header X-Service-UID being set if `APACHE_HEADER_X_SERVICE_UID` is empty.
- Adds support for defining `APACHE_CUSTOM_LOG_LOCATION` and `APACHE_ERROR_LOG_LOCATION` paths that are relative to `APACHE_CONTENT_ROOT`. This allows for a simplified configuration.
- Prevents `scmi` installer publishing port 443 if `APACHE_MOD_SSL_ENABLED` is false.
- Adds a fix for the default value of `APACHE_HEADER_X_SERVICE_UID` when using `scmi`.
- Adds method to prevent exposed ports being published when installing using the embedded `scmi` installation method or the Makefile's create/run template. e.g. To prevent port `8443` getting published set the value of the environment variable `DOCKER_PORT_MAP_TCP_8443` to `NULL`
- Disables publishing port `8443` by default in scmi/make/systemd install templates.

### 1.6.1 - 2016-09-09

- Adds default of `expose_php = Off` even if the user configuration is not loaded.
- Adds `PACKAGE_PATH` environment variable to the bootstrap.
- Loading of app PHP configuration is now carried out in the bootstrap before starting `httpd` (Apache) and not as an image build time step. This is necessary to allow the environment variables to be replaced before being loaded by the fcgid php-wrapper script where the environment is cleared down.
- Removes redundant image build step. This should have been removed before release of 1.6.0
- Adds app package fcgid configuration. Used when building with fcgid support.
- Adds loading of Apache app package configuration files into the bootstrap.
- Removes a now redundant image build step.
- Adds enable/disable of the SSL VirtualHost configuration into the bootstrap.

### 1.6.0 - 2016-09-08

- Adds fix for issues running `make dist` before creating package path.
- Adds fix for incorrect etcd key/value path in systemd template unit-file.
- Relocates VirtualHost configuration out of app package and into the container package.
- Adds simplified php-wrapper script now that configuration is handled by the php.d/\*ini scan directory includes.
- Adds restructured httpd configuration. Replaced the single template VirtualHost that was used to generate an SSL copy using the bootstrap script with 2 basic VirtualHost definitions. The majority of configuration is now pulled in from the scan directory `/etc/services-config/httpd/conf.d/*.conf` where core container configuration is prefixed with `00-`. App package configuration (`/var/www/app/etc/httpd/conf.d/*.conf`) files are added to this directory as part of the container build and prefixed with `50-` to indicate their source and influence load order.
- Adds the PHP Info script into the demo app package the source instead of generating it as part of the container build.
- Adds an increased MaxKeepAliveRequests value of 200 from the default 100.
- Removes some unused configuration scripts.
- Fixes an issue with the php-wrapper script not loading in the configuration environment variables from `/etc/httpd-bootstrap.conf`.
- Adds minor improvement to the demo app's index.php to prevent errors if either the PHP Info or  APC Info scripts are unavailable.
- The placeholder `{{HOSTNAME}}` will be replaced with the system (container) hostname when used in the value of the environment variable `SERVICE_UID`.

### 1.5.0 - 2016-09-04

- Updates upstream source tag to `centos-6-1.6.0` (i.e. Updated to CentOS-6.8).
- Adds `APACHE_OPERATING_MODE` to the systemd run command.
- Disables the default Apache DocumentRoot `/var/www/html`.
- Disables the `TRACE` method in the VirtualHost configuration.
- Updates examples in README.
- Updates SSL configuration to use 2048 bit key size to reduce CPU usage.
- Enables `SSLSessionCache` in the VirtualHost configuration.
- Updates SSL configuration to use Mozilla recommended cipher suites and order.
- Maintenance: Use single a line ENV to set all environment variables.
- Fixes an issue with log paths being incorrect due to `APACHE_CONTENT_ROOT` being undefined.
- Removes use of "AllowOverride All" in the VirtualHost configuration when no .htaccess exists in the DocumentRoot path. This would otherwise log the following error: "(13)Permission denied: /var/www/app/public_html/.htaccess pcfg_openfile: unable to check htaccess file, ensure it is readable"
- Adds Makefile to replace build.sh and run.sh
- Updates systemd template unit-files.
- Updates and relocates bootstrap script.
- Restructures supervisord configuration and adds improvements to bootstrap reliability.

### 1.4.5 - 2016-04-25

- Fixed issue with httpd.conf syntax errors on startup if using a named data volume mapping to /var/www instead of /var/www/app - which results in /var/www/html being unavailable.
- Disable TRACE method globally. It's only required for debugging so can be enabled in the VirtualHost if necessary.
- Fixed issue with duplicate comment characters in /etc/sysconfig/httpd.
- Use `etc/services-config/php/php.d/00-php.ini` and `var/www/app/etc/php.d/50-php.ini` to define Global and Application PHP settings.
- Added Apache configuration parameter `APACHE_OPERATING_MODE` for production,development and debug modes.
- Prevent invalid or unavailable Apache module identifiers in the apache-bootstrap.
- Use a single environment variable `SERVICE_UID` to define the 'X-Service-Uid' Header value. This replaces the use of `SERVICE_UNIT_INSTANCE`, `SERVICE_UNIT_LOCAL_ID`, and `SERVICE_UNIT_INSTANCE`.

VirtualHost improvements:
- Added correct MIME type for .ico, opentype and web fonts not defined in /etc/mime.types.
- Added correct encoding for svgz filetype.
- Identify known cases of invalidated Accept-Encoding request headers.
- Expand on the filetypes that should be output compressed.
- Expand on the filetypes that should set a 7 day expires header.
- Added Cache-Control header to allow browser to cache 204 /favicon.ico responses. Appears to only work over HTTP protocol.

### 1.4.4 - 2016-03-10

- Improved self-signed certificate generation.
- Increased process limits to 85 soft a 170 hard.
- Sort the Apache modules in log output.
- Added php-wrapper to the app source.
- Locate the fcgid php-wrapper script within the package directory.
- Remove VirtualHost configuration that can be added to fcgid.conf instead.
- Deprecate `APACHE_SUEXEC_USER_GROUP` which is not necessary in containerised app after adding support for `APACHE_RUN_USER` and `APACHE_RUN_GROUP`.

### 1.4.3 - 2016-03-04

- Fixed issue with thread limit being too restrictive.
- Improved systemd install script.
- Added app group to the apache system user account.
- Corrected app root/install directory permissions.
- No longer display SSL certificate that is later removed in the docker build output.
- Generate the SSL VirtualHost configuration file only when required; do not store a copy unnecessarily.
- Fixed server-status Location in repository copy of httpd.conf (not an issue in container build).
- Added `APACHE_RUN_USER` and `APACHE_RUN_GROUP` to define the account which Apache runs under. Thread limits are now defined for the apache group instead of by username.
- Use system user accounts instead of standard accounts and use names instead of UID/GID values where applicable.
- Removed `SERVICE_USER_GROUP` in favour of `APACHE_RUN_USER`.
- Removed `SERVICE_USER_PASSWORD` and prevent display of system account passwords from logs.
- Prevent attempts to change system user login to that of existing user.
- Prevent the root/install directory being populated with the user skeleton directory (/etc/skel) contents.
- Remove symbolic link `/home/app` to the root/install directory.
- Include app directory structure in the source instead of creating empty directories as a build step.
- Updated "Hello, world!" app index.php to Bootstrap 3.3.6 from 3.1.1.
- Rationalised environment variable names. The deprecated names are still added to the environment to allow existing vhost.conf files that may be stored on container's data volumes to continue to function. Environment variables changes {old-name} => {new-name}:
  - `APP_HOME_DIR` => `APACHE_CONTENT_ROOT`
  - `DATE_TIMEZONE` => `PHP_OPTIONS_DATE_TIMEZONE`
  - `SERVICE_USER` => `APACHE_SYSTEM_USER`
  - `SUEXECUSERGROUP` => `APACHE_SUEXEC_USER_GROUP`
- Remove requirement for .app-skel; Install to `PACKAGE_PATH` and link to, (or copy if necessary to), `APACHE_CONTENT_ROOT`. Created on first run instead of storing a copy on container.
- Added `APACHE_PUBLIC_DIRECTORY` to define the public web directory relative to `APACHE_CONTENT_ROOT`.
- EnableSendfile Apache directive is set to off if DocumentRoot is detected as an `nfs` type file system.
- Enable TLS > 1.0 and disable RC4-RCA and LOW Cipher Suites in SSL VirtualHost configuration.
- Reduced initialisation/startup time and reduced time for docker logs output to appear.
- Add feature to allow operator to customise Apache access and error log configuration using environment variables.

### 1.4.2 - 2016-01-24

- Updated upstream source tag to 1.4.2.
- Revised method + instructions on data volume usage.
- Improved systemd definition file and installation script.
- Fixed issue with populating app home directory if exists but empty.
- Reverted change to URI of the Apache status feature from /\_httpdstatus to /server-status. This allows the `apachectl status|fullstatus` commands to function correctly.

### 1.4.1 - 2016-01-23

- Updated source tag to 1.4.1.
- Implement HTTPD environment variable to allow operator to switch between httpd (Prefork) and httpd.worker (Worker) MPM.
- Removed references to Composer as it has not been included as part of the container build.
- Populate the container's /etc/hosts with `APACHE_SERVER_NAME` and `APACHE_SERVER_ALIAS` values.
- Split out the HTTP and HTTPS configuration includes and comment/uncomment entire block for the SSL configuration instead of targeting each line. _NOTE_ If you are using an existing vhost.conf and want to use the mod_ssl feature of the container instead of terminating the SSL upstream then you should update the mod_ssl configuration to the following (with the '#' at the beginning of the line):

  ```
  #        <IfModule mod_ssl.c>
  #                SSLEngine on
  #                SSLOptions +StrictRequire
  #                SSLProtocol -all +TLSv1
  #                SSLCipherSuite ALL:!aNULL:!ADH:!eNULL:!LOW:!EXP:RC4+RSA:+HIGH:+MEDIUM
  #                SSLCertificateFile /etc/pki/tls/certs/localhost.crt
  #                SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
  #                #SSLCACertificateFile /etc/pki/tls/certs/ca-bundle.crt
  #        </IfModule>
  ```
- Add function to set Apache's main ServerName to suppress startup message.
- Disable ExtendedStatus by default and add environment variable to allow it to be enabled by the operator.

### 1.4.0 - 2015-12-24

- Updated to CentOS 6.7.

### 1.3.1 - 2015-12-23

- Updated upstream image to centos-6-1.3.1 tag.
- Update packages httpd and mod_ssl.
- Fixed 'Error: could not find config file /etc/supervisord.conf' being logged on non Darwin docker hosts when using the run.sh helper script.
- Fixed issue with setting the default tag in the build.sh helper script.
- Use local scope variables in bash helper script functions.
- Update bootstrap and vhost.conf for FCGID php-wrapper directory path change.
- Updated the systemd definition file and installer script. Now using etcd2.
- Add 'rpm --rebuilddb' before yum install to resolve checksum issues that prevented build completion.
- Added feature to apply config via environment variables + documentation updated with example use cases.
- Added Apache module reqtimeout_module.

### 1.3.0 - 2015-07-12

- Build from a specified tag instead of branch.
- Specify package versions, add versionlock package and lock packages.
- Locate the SSH configuration file in a subdirectory to be more consistent.
- Added support for running and building on Mac Docker hosts (when using boot2docker).

### 1.2.1 - 2015-05-25

- Updated the systemd service file to reference the correct tag version.
- Fixed some spelling errors in the README

### 1.2.0 - 2015-05-04

- Updated to CentOS 6.6 from 6.5
- Added MIT License

### 1.0.1 - 2014-10-23

- Reduce the number of layers required to build the image. This reduces the chance of hitting the 127 layer limit and should speed up build and pull tasks.

### 1.0.0 - 2014-08-28

- Initial release