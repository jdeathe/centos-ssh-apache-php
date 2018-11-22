centos-ssh-apache-php
=====================

Docker Image including: 

- CentOS-6 6.10 x86_64, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1.
- CentOS-6 6.10 x86_64, Apache 2.4, PHP-FPM 5.6, PHP memcached 2.2, Zend Opcache 7.0.
- CentOS-7 7.5.1804 x86_64, Apache 2.4, PHP-FPM 7.2, PHP memcached 3.0, Zend Opcache 7.2.

Apache PHP web server, loading only a minimal set of Apache modules by default. Supports custom configuration via environment variables.

## Overview & links

### Tags and respective `Dockerfile` links

- `centos-7-httpd24u-php72u`, `centos-7-httpd24u-php72u-3.1.0`, `3.1.0` [(centos-7-httpd24u-php72u/Dockerfile)](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-7-httpd24u-php72u/Dockerfile)
- `centos-6-httpd24u-php56u`, `centos-6-httpd24u-php56u-2.3.0`, `2.3.0` [(centos-6-httpd24u-php56u/Dockerfile)](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6-httpd24u-php56u/Dockerfile)
- `centos-6`, `centos-6-1.11.0`, `1.11.0` [(centos-6/Dockerfile)](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/Dockerfile)

#### centos-6

The latest CentOS-6 Standard Package based release can be pulled from the `centos-6` Docker tag. It is recommended to select a specific release tag - the convention is `centos-6-1.11.0` or `1.11.0` for the [1.11.0](https://github.com/jdeathe/centos-ssh-apache-php/tree/1.11.0) release tag. This build of [Apache](https://httpd.apache.org/), (httpd CentOS package), uses the mpm_prefork_module and php5_module modules for handling [PHP](http://php.net/).

#### centos-6-httpd24u-php56u

The latest CentOS-6 [IUS](https://ius.io) Apache 2.4, [IUS](https://ius.io) PHP-FPM 5.6 based release can be pulled from the `centos-6-httpd24u-php56u` Docker tag. It is recommended to select a specific release tag - the convention is `centos-6-httpd24u-php56u-2.3.0` or `2.3.0` for the [2.3.0](https://github.com/jdeathe/centos-ssh-apache-php/tree/2.3.0) release tag. This build of [Apache](https://httpd.apache.org/), (httpd24u package), uses the mpm_prefork_module and php-fpm for handling [PHP](http://php.net/). This version has the option of using the worker or event MPM.

#### centos-7-httpd24u-php72u

The latest CentOS-7 [IUS](https://ius.io) Apache 2.4, [IUS](https://ius.io) PHP-FPM 7.2 based release can be pulled from the `centos-7-httpd24u-php72u` Docker tag. It is recommended to select a specific release tag - the convention is `centos-7-httpd24u-php72u-3.1.0` or `3.1.0` for the [3.1.0](https://github.com/jdeathe/centos-ssh-apache-php/tree/3.1.0) release tag. This build of [Apache](https://httpd.apache.org/), uses the mpm_prefork_module and php-fpm for handling [PHP](http://php.net/). This version has the option of using the worker or event MPM.

Included in the build are the [SCL](https://www.softwarecollections.org/), [EPEL](http://fedoraproject.org/wiki/EPEL) and [IUS](https://ius.io) repositories. Installed packages include [OpenSSH](http://www.openssh.com/portable.html) secure shell, [vim-minimal](http://www.vim.org/), [elinks](http://elinks.or.cz) (for fullstatus support), PHP [Memcached](http://pecl.php.net/package/memcached) are installed along with python-setuptools, [supervisor](http://supervisord.org/) and [supervisor-stdout](https://github.com/coderanger/supervisor-stdout). The `centos-6` "Standard" PHP 5.3 build includes PHP [APC](http://pecl.php.net/package/APC) where Zend Opcache is bundled in PHP 5.6 and 7.2.

Supervisor is used to start the httpd (and, if applicable, php-fpm) daemon when a docker container based on this image is run. To enable simple viewing of stdout for the service's subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs {docker-container-name}`.

If enabling and configuring SSH access, it is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

### SSH Alternatives

SSH is not required in order to access a terminal for the running container. The simplest method is to use the docker exec command to run bash (or sh) as follows:

```
$ docker exec -it {docker-name-or-id} bash
```

For cases where access to docker exec is not possible the preferred method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/command-keys.md) for details on how to set this up.

## Quick Example

Run up a container named `apache-php.pool-1.1.1` from the docker image `jdeathe/centos-ssh-apache-php` on port 8080 of your docker host.

```
$ docker run -d \
  --name apache-php.pool-1.1.1 \
  -p 8080:80 \
  -e "APACHE_SERVER_NAME=app-1.local" \
  jdeathe/centos-ssh-apache-php:1.11.0
```

Now point your browser to `http://{docker-host}:8080` where `{docker-host}` is the host name of your docker server and, if all went well, you should see the "Hello, world!" page.

![PHP "Hello, world!" - Chrome screenshot](https://raw.github.com/jdeathe/centos-ssh-apache-php/centos-6/images/php-hello-world-chrome.png)

To be able to access the server using the "app-1.local" domain name you need to add a hosts file entry locally; such that the IP address of the Docker host resolves to the name "app-1.local". Alternatively, you can use the elinks browser installed in the container. Note that because you are using the browser from the container you access the site over port 80.

```
$ docker exec -it apache-php.pool-1.1.1 \
  elinks http://app-1.local
```

![PHP "Hello, world!" - eLinks screenshot](https://raw.github.com/jdeathe/centos-ssh-apache-php/centos-6/images/php-hello-world-elinks.png)

To verify the container is initialised and running successfully by inspecting the container's logs.

```
$ docker logs apache-php.pool-1.1.1
```

On first run, the bootstrap script, ([/usr/sbin/httpd-bootstrap](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/src/usr/sbin/httpd-bootstrap)), will check if the DocumentRoot directory is empty and, if so, will populate it with the example app scripts and app specific configuration files.

The `apachectl` command can be accessed as follows.

```
$ docker exec -it apache-php.pool-1.1.1 \
	bash -c "apachectl -h"
```

## Instructions

### Running

To run the a docker container from this image you can use the standard docker commands. Alternatively, you can use the embedded (Service Container Manager Interface) [scmi](https://github.com/jdeathe/centos-ssh/blob/centos-6/src/usr/sbin/scmi) that is included in the image since `centos-6-1.7.2` or, if you have a checkout of the [source repository](https://github.com/jdeathe/centos-ssh-apache-php), and have make installed the Makefile provides targets to build, install, start, stop etc. where environment variables can be used to configure the container options and set custom docker run parameters.

#### SCMI Installation Examples

The following example uses docker to run the SCMI install command to create and start a container named `apache-php.pool-1.1.1`. To use SCMI it requires the use of the `--privileged` docker run parameter and the docker host's root directory mounted as a volume with the container's mount directory also being set in the `scmi` `--chroot` option. The `--setopt` option is used to add extra parameters to the default docker run command template; in the following example a named configuration volume is added which allows the SSH host keys to persist after the first container initialisation. Not that the placeholder `{{NAME}}` can be used in this option and is replaced with the container's name.

##### SCMI Install

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  --env BASH_ENV="" \
  --env ENV="" \
  jdeathe/centos-ssh-apache-php:1.11.0 \
  /usr/sbin/scmi install \
    --chroot=/media/root \
    --tag=1.11.0 \
    --name=apache-php.pool-1.1.1
```

##### SCMI Uninstall

To uninstall the previous example simply run the same docker run command with the scmi `uninstall` command.

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  --env BASH_ENV="" \
  --env ENV="" \
  jdeathe/centos-ssh-apache-php:1.11.0 \
  /usr/sbin/scmi uninstall \
    --chroot=/media/root \
    --tag=1.11.0 \
    --name=apache-php.pool-1.1.1
```

##### SCMI Systemd Support

If your docker host has systemd (and optionally etcd) installed then `scmi` provides a method to install the container as a systemd service unit. This provides some additional features for managing a group of instances on a single docker host and has the option to use an etcd backed service registry. Using a systemd unit file allows the System Administrator to use a Drop-In to override the settings of a unit-file template used to create service instances. To use the systemd method of installation use the `-m` or `--manager` option of `scmi` and to include the optional etcd register companion unit use the `--register` option.

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  --env BASH_ENV="" \
  --env ENV="" \
  jdeathe/centos-ssh-apache-php:1.11.0 \
  /usr/sbin/scmi install \
    --chroot=/media/root \
    --tag=1.11.0 \
    --name=apache-php.pool-1.1.1 \
    --manager=systemd \
    --register \
    --env='APACHE_MOD_SSL_ENABLED=true' \
    --setopt='--volume {{NAME}}.data-ssl:/etc/services-config/ssl'
```

##### SCMI Fleet Support

**_Deprecation Notice:_** The fleet project is no longer maintained. The fleet `--manager` option has been deprecated in `scmi`.

If your docker host has systemd, fleetd (and optionally etcd) installed then `scmi` provides a method to schedule the container  to run on the cluster. This provides some additional features for managing a group of instances on a [fleet](https://github.com/coreos/fleet) cluster and has the option to use an etcd backed service registry. To use the fleet method of installation use the `-m` or `--manager` option of `scmi` and to include the optional etcd register companion unit use the `--register` option.

##### SCMI Image Information

Since release `centos-6-1.7.2` the install template has been added to the image metadata. Using docker inspect you can access `scmi` to simplify install/uninstall tasks.

_NOTE:_ A prerequisite of the following examples is that the image has been pulled (or loaded from the release package).

```
$ docker pull jdeathe/centos-ssh-apache-php:1.11.0
```

To see detailed information about the image run `scmi` with the `--info` option. To see all available `scmi` options run with the `--help` option.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.install}}" \
    jdeathe/centos-ssh-apache-php:1.11.0
  ) --info"
```

To perform an installation using the docker name `apache-php.pool-1.2.1` simply use the `--name` or `-n` option.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.install}}" \
    jdeathe/centos-ssh-apache-php:1.11.0
  ) --name=apache-php.pool-1.2.1"
```

To uninstall use the *same command* that was used to install but with the `uninstall` Label.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.uninstall}}" \
    jdeathe/centos-ssh-apache-php:1.11.0
  ) --name=apache-php.pool-1.2.1"
```

##### SCMI on Atomic Host

With the addition of install/uninstall image labels it is possible to use [Project Atomic's](http://www.projectatomic.io/) `atomic install` command to simplify install/uninstall tasks on [CentOS Atomic](https://wiki.centos.org/SpecialInterestGroup/Atomic) Hosts.

To see detailed information about the image run `scmi` with the `--info` option. To see all available `scmi` options run with the `--help` option.

```
$ sudo -E atomic install \
  -n apache-php.pool-1.3.1 \
  jdeathe/centos-ssh-apache-php:1.11.0 \
  --info
```

To perform an installation using the docker name `apache-php.pool-1.3.1` simply use the `-n` option of the `atomic install` command.

```
$ sudo -E atomic install \
  -n apache-php.pool-1.3.1 \
  jdeathe/centos-ssh-apache-php:1.11.0
```

Alternatively, you could use the `scmi` options `--name` or `-n` for naming the container.

```
$ sudo -E atomic install \
  jdeathe/centos-ssh-apache-php:1.11.0 \
  --name apache-php.pool-1.3.1
```

To uninstall use the *same command* that was used to install but with the `uninstall` Label.

```
$ sudo -E atomic uninstall \
  -n apache-php.pool-1.3.1 \
  jdeathe/centos-ssh-apache-php:1.11.0
```

#### Environment Variables

There are environmental variables available which allows the operator to customise the running container.

##### APACHE_AUTOSTART_HTTPD_BOOTSTRAP & APACHE_AUTOSTART_HTTPD_WRAPPER

It may be desirable to prevent the startup of the httpd-bootstrap and/or httpd-wrapper scripts. For example, when using an image built from this Dockerfile as the source for another Dockerfile you could disable services from startup by setting `APACHE_AUTOSTART_HTTPD_WRAPPER` to `false`. The benefit of this is to reduce the number of running processes in the final container. Another use for this would be to make use of the packages installed in the image such as `ab`, `curl`, `elinks`, `php-cli` etc.

##### APACHE_SERVER_NAME & APACHE_SERVER_ALIAS

The `APACHE_SERVER_NAME` and `APACHE_SERVER_ALIAS` environmental variables are used to set the VirtualHost `ServerName` and `ServerAlias` values respectively. If the value contains the placeholder `{{HOSTNAME}}` it will be replaced with the system `hostname` value; by default this is the container id but the hostname can be modified using the `--hostname` docker create|run parameter.

In the following example the running container would respond to the host names `app-1.local` or `app-1`.

```
...
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
...
```

##### APACHE_CONTENT_ROOT

The home directory of the service user and parent directory of the Apache DocumentRoot is /var/www/app by default but can be changed if necessary using the `APACHE_CONTENT_ROOT` environment variable.

```
...
  --env "APACHE_CONTENT_ROOT=/var/www/app-1" \
...
```

from your browser you can then access it with `http://app-1.local:8080` assuming you have the IP address of your docker mapped to the hostname using your DNS server or a local hosts entry.

##### APACHE_CUSTOM_LOG_LOCATION & APACHE_CUSTOM_LOG_FORMAT

The Apache CustomLog can be defined using `APACHE_CUSTOM_LOG_LOCATION` to set a file, (or pipe), location and `APACHE_CUSTOM_LOG_FORMAT` to specify the required LogFormat nickname.

```
...
  --env "APACHE_CUSTOM_LOG_LOCATION=/var/log/httpd/access_log" \
  --env "APACHE_CUSTOM_LOG_FORMAT=common" \
...
```

To set a file path relative to `APACHE_CONTENT_ROOT` the path value should exclude a leading `/`.

```
...
  --env "APACHE_CUSTOM_LOG_LOCATION=var/log/httpd_access_log" \
...
```

##### APACHE_ERROR_LOG_LOCATION & APACHE_ERROR_LOG_LEVEL

The Apache ErrorLog can be defined using `APACHE_ERROR_LOG_LOCATION` to set a file, (or pipe), location and `APACHE_ERROR_LOG_LEVEL` to specify the required LogLevel value.

```
...
  --env "APACHE_ERROR_LOG_LOCATION=/var/log/httpd/error_log" \
  --env "APACHE_ERROR_LOG_LEVEL=error" \
...
```

To set a file path relative to `APACHE_CONTENT_ROOT` the path value should exclude a leading `/`.

```
...
  --env "APACHE_ERROR_LOG_LOCATION=var/log/httpd_error_log" \
...
```

##### APACHE_EXTENDED_STATUS_ENABLED

The variable `APACHE_EXTENDED_STATUS_ENABLED` allows you to turn ExtendedStatus on. It is turned off by default as it has an impact on the server's performance but with it enabled you can gather more statistics.

```
...
  --env "APACHE_EXTENDED_STATUS_ENABLED=true" \
...
```

You can view the output from Apache server-status either using the elinks browser from onboard the container or by using `watch` and `curl` to monitor status over time. The following command shows the server-status updated at a 1 second interval given an `APACHE_SERVER_NAME` or `APACHE_SERVER_ALIAS` of "app-1.local".

```
$ docker exec -it apache-php.pool-1.1.1 \
  env TERM=xterm \
  watch -n 1 \
  -d "curl -sH 'Host: app-1.local' http://127.0.0.1/server-status?auto"
```

##### APACHE_HEADER_X_SERVICE_UID

The `APACHE_HEADER_X_SERVICE_UID` environmental variable is used to set a response header named `X-Service-UID` that lets you identify the container that is serving the content. This is useful when you have many containers running on a single host using different ports or if you are running a cluster and need to identify which host the content is served from. If the value contains the placeholder `{{HOSTNAME}}` it will be replaced with the system `hostname` value; by default this is the container id but the hostname can be modified using the `--hostname` docker create|run parameter.

```
...
  --env "APACHE_HEADER_X_SERVICE_UID={{HOSTNAME}}" \
...
```

##### APACHE_LOAD_MODULES

By default, the image loads a minimal set of required Apache modules. To load additional modules the `APACHE_LOAD_MODULES` can be used. To load both the `mod_env` and `mod_rewrite` Apache Modules use the respective module identifiers. i.e. `env_module` and `rewrite_module`.

```
...
  --env "APACHE_LOAD_MODULES=env_module rewrite_module"
...
```

##### APACHE_MOD_SSL_ENABLED

By default SSL support is disabled but a second port, (mapped to 8443), is available for traffic that has been been through upstream SSL termination (SSL Offloading). If you want the container to support SSL directly then set `APACHE_MOD_SSL_ENABLED=true` this will then generate a self signed certificate and will update Apache to accept traffic on port 443.

```
$ docker stop apache-php.pool-1.1.1 && \
  docker rm apache-php.pool-1.1.1
$ docker run -d \
  --name apache-php.pool-1.1.1 \
  --publish 8080:80 \
  --publish 9443:443 \
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "APACHE_MOD_SSL_ENABLED=true" \
  --volume apache-php.pool-1.1.1.data-ssl:/etc/services-config/ssl \
  jdeathe/centos-ssh-apache-php:1.11.0
```

##### APACHE_MPM

Using `APACHE_MPM` the Apache MPM can be set. Defaults to `prefork` and in most cases this shouldn't be altered.

```
...
  --env "APACHE_MPM=prefork" \
...
```

##### APACHE_RUN_USER & APACHE_RUN_GROUP

The Apache process is run by the User and Group defined by `APACHE_RUN_USER` and `APACHE_RUN_GROUP` respectively.

```
...
  --env "APACHE_RUN_GROUP=www-app" \
  --env "APACHE_RUN_USER=www-app" \
...
```

##### APACHE_PUBLIC_DIRECTORY

The public directory is relative to the `APACHE_CONTENT_ROOT` and together they form the Apache DocumentRoot path. The default value is `public_html` and should not be changed unless changes are made to the source of the app to include an alternative public directory such as `web` or `public`.

```
...
  --env "APACHE_PUBLIC_DIRECTORY=web" \
...
```

##### APACHE_SSL_CERTIFICATE

The `APACHE_SSL_CERTIFICATE` environment variable is used to define a PEM encoded certificate bundle. To make a compatible certificate bundle use the `cat` command to combine the certificate files together.

```
$ cat /usr/share/private/server-key.pem \
    /usr/share/certs/server-certificate.pem \
    /usr/share/certs/intermediate-certificate.pem \
  > /usr/share/certs/server-bundle.pem
```

Base64 encoding of the PEM file contents is recommended if not using the file path method.

*Note:* The `base64` command on Mac OSX will encode a file without line breaks by default but if using the command on Linux you need to include use the `-w` option to prevent wrapping lines at 80 characters. i.e. `base64 -w 0 -i {certificate-path}`.

```
...
  --env "APACHE_SSL_CERTIFICATE=$(
    base64 -i "/usr/share/certs/server-bundle.pem"
  )" \
...
```

If set to a valid container file path the value will be read from the file - this allows for setting the value securely when combined with an orchestration feature such as Docker Swarm secrets.

```
...
  --env "APACHE_SSL_CERTIFICATE=/run/secrets/apache_ssl_certificate" \
...
```

##### APACHE_SSL_CIPHER_SUITE

Use the `APACHE_SSL_CIPHER_SUITE` environment variable to define an appropriate Cipher Suite. The default "intermediate" selection should be suitable for most use-cases where support for a wide range browsers is necessary. 

References:
- [OpenSSL ciphers documentation](https://www.openssl.org/docs/manmaster/apps/ciphers.html).
- [Mozilla Security/Server Side TLS guidance](https://wiki.mozilla.org/Security/Server_Side_TLS).

*Note:* The value show is using space separated values to allow for readablity in the documentation; this is valid syntax however using the colon separator is the recommended form.

```
...
  --env "APACHE_SSL_CIPHER_SUITE=ECDHE-ECDSA-AES256-GCM-SHA384 \
ECDHE-RSA-AES256-GCM-SHA384 ECDHE-ECDSA-CHACHA20-POLY1305 \
ECDHE-RSA-CHACHA20-POLY1305 ECDHE-ECDSA-AES128-GCM-SHA256 \
ECDHE-RSA-AES128-GCM-SHA256 ECDHE-ECDSA-AES256-SHA384 \
ECDHE-RSA-AES256-SHA384 ECDHE-ECDSA-AES128-SHA256 \
ECDHE-RSA-AES128-SHA256" \
...
```

##### APACHE_SSL_PROTOCOL

Use the `APACHE_SSL_PROTOCOL` environment variable to define the supported protocols. The default protocols are suitable for most "intermediate" use-cases however you might want to restrict the TLS version support for example.

```
...
  --env "APACHE_SSL_PROTOCOL=All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1" \
...
```

##### APACHE_SYSTEM_USER

Use the `APACHE_SYSTEM_USER` environment variable to define a custom service username.

```
...
  --env "APACHE_SYSTEM_USER=app-1" \
...
```

##### PHP_OPTIONS_DATE_TIMEZONE

The default timezone for the container, and the PHP app, is UTC however the operator can set an appropriate timezone using the `PHP_OPTIONS_DATE_TIMEZONE` variable. The value should be a timezone identifier, like UTC or Europe/London. The list of valid identifiers is available in the PHP [List of Supported Timezones](http://php.net/manual/en/timezones.php).

To set the timezone for the UK and account for British Summer Time you would use:

```
...
  --env "PHP_OPTIONS_DATE_TIMEZONE=Europe/London" \
...
```

##### PHP_OPTIONS_SESSION_NAME, PHP_OPTIONS_SESSION_SAVE_HANDLER & PHP_OPTIONS_SESSION_SAVE_PATH

Using `PHP_OPTIONS_SESSION_SAVE_HANDLER` and `PHP_OPTIONS_SESSION_SAVE_PATH` together it's possible to configure PHP to use an alternative `session.save_handler` and `session.save_path`. For example if you have a Memcached server running on the host `memcached-server` on the default port `11211` the following configuration will allow session data to be stored in Memcached, allowing session data to be shared between multiple PHP containers.

Using `PHP_OPTIONS_SESSION_NAME` a session name can be defined - otherwise the default name "PHPSESSID" is used. 

```
...
  --env "PHP_OPTIONS_SESSION_NAME=app-session" \
  --env "PHP_OPTIONS_SESSION_SAVE_HANDLER=memcached" \
  --env "PHP_OPTIONS_SESSION_SAVE_PATH=memcached-server:11211" \
...
```

If using the files handler, to set a save path relative to `APACHE_CONTENT_ROOT` the path value should exclude a leading `/`.

```
...
  --env "PHP_OPTIONS_SESSION_SAVE_HANDLER=files" \
  --env "PHP_OPTIONS_SESSION_SAVE_PATH=var/session" \
...
```
