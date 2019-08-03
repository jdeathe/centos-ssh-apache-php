### Tags and respective `Dockerfile` links

- `centos-7-httpd24u-php72u`, `3.3.1` [(centos-7-httpd24u-php72u/Dockerfile)](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-7-httpd24u-php72u/Dockerfile)
- `centos-6`, `1.13.1` [(centos-6/Dockerfile)](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/Dockerfile)

## Overview

Apache PHP web server, loading only a minimal set of Apache modules by default.

This build uses the base image [jdeathe/centos-ssh](https://github.com/jdeathe/centos-ssh) so inherits it's features but with `sshd` disabled by default. [Supervisor](http://supervisord.org/) is used to start the Apache [`httpd`](https://httpd.apache.org/) daemon when a docker container based on this image is run.

### Image variants

- [IUS Apache 2.4, IUS PHP-FPM 7.2, PHP memcached 3.0, PHP redis 3.1, Zend Opcache 7.2 - CentOS-7](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-7-httpd24u-php72u)
- [Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP redis 2.2, PHP APC 3.1 - CentOS-6](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6)

## Quick start

> For production use, it is recommended to select a specific release tag as shown in the examples.

Run up a container named `apache-php.1` from the docker image `jdeathe/centos-ssh-apache-php` on port 8080 of your docker host.

```
$ docker run -d \
  --name apache-php.1 \
  -p 8080:80 \
  -e "APACHE_SERVER_NAME=app-1.local" \
  jdeathe/centos-ssh-apache-php:3.3.1
```

Go to `http://{{docker-host}}:8080` using a browser where `{{docker-host}}` is the host name of your docker server and, if all went well, you should see the "Hello, world!" page.

![PHP "Hello, world!" - Chrome screenshot](https://raw.github.com/jdeathe/centos-ssh-apache-php/centos-7-httpd24u-php72u/images/php-hello-world-chrome-v3.3.2.png)

To be able to access the server using the "app-1.local" domain name you need to add a hosts file entry locally; such that the IP address of the Docker host resolves to the name "app-1.local". Alternatively, you can use the `elinks` browser installed in the container.

> Note that because you are using the browser from the container you access the site over the standard port 80.

```
$ docker exec -it apache-php.1 \
  elinks http://app-1.local
```

![PHP "Hello, world!" - eLinks screenshot](https://raw.github.com/jdeathe/centos-ssh-apache-php/centos-7-httpd24u-php72u/images/php-hello-world-elinks-v3.3.2.png)

Verify the named container's process status and health.

```
$ docker ps -a \
  -f "name=apache-php.1"
```

Verify successful initialisation of the named container.

```
$ docker logs apache-php.1
```

On first run, if the DocumentRoot directory is empty, it will be populated with the example app scripts and app specific configuration files.

The `apachectl` command can be accessed as follows.

```
$ docker exec -it apache-php.1 \
  apachectl -h
```

## Instructions

### Running

To run the a docker container from this image you can use the standard docker commands as shown in the example below. Alternatively, there's a [docker-compose](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-7-httpd24u-php72u/docker-compose.yml) example.

For production use, it is recommended to select a specific release tag as shown in the examples.

#### Using environment variables

```
$ docker stop apache-php.1 && \
  docker rm apache-php.1; \
  docker run -d \
  --name apache-php.1 \
  --publish 8080:80 \
  --publish 9443:443 \
  --env "APACHE_CUSTOM_LOG_LOCATION=/dev/stdout" \
  --env "APACHE_ERROR_LOG_LOCATION=/dev/stderr" \
  --env "APACHE_EXTENDED_STATUS_ENABLED=true" \
  --env "APACHE_LOAD_MODULES=env_module rewrite_module" \
  --env "APACHE_MOD_SSL_ENABLED=true" \
  --env "APACHE_MPM=event" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "APACHE_SSL_PROTOCOL=All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1" \
  --env "PHP_OPTIONS_DATE_TIMEZONE=Europe/London" \
  jdeathe/centos-ssh-apache-php:3.3.1
```

#### Environment Variables

There are environmental variables available which allows the operator to customise the running container.

##### ENABLE_HTTPD_BOOTSTRAP, ENABLE_HTTPD_WRAPPER & ENABLE_PHP_FPM_WRAPPER

It may be desirable to prevent the startup of the `httpd-bootstrap`, `httpd-wrapper`, and/or, `php-fpm-wrapper` scripts. For example, when using an image built from this Dockerfile as the source for another Dockerfile you could disable services from startup by setting `ENABLE_HTTPD_WRAPPER` and `ENABLE_PHP_FPM_WRAPPER` to `false`. The benefit of this is to reduce the number of running processes in the final container. Another use for this would be to make use of the packages installed in the image such as `ab`, `curl`, `elinks`, `php-cli` etc.

##### APACHE_CONTENT_ROOT

The home directory of the service user and parent directory of the Apache DocumentRoot is `/var/www/app` by default but can be changed if necessary using the `APACHE_CONTENT_ROOT` environment variable.

```
...
  --env "APACHE_CONTENT_ROOT=/var/www/app-1" \
...
```

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

You can view the output from Apache server-status either using the `elinks` browser from onboard the container or by using `watch` and `curl` to monitor status over time. The following command shows the server-status updated at a 1 second interval given an `APACHE_SERVER_NAME` or `APACHE_SERVER_ALIAS` of "app-1.local".

```
$ docker exec -it apache-php.1 \
  env TERM=xterm \
  watch -n 1 \
  -d "curl -s \
    -H 'Host: app-1.local' \
    http://127.0.0.1/server-status?auto"
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
$ docker stop apache-php.1 && \
  docker rm apache-php.1; \
  docker run -d \
  --name apache-php.1 \
  --publish 8080:80 \
  --publish 9443:443 \
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "APACHE_MOD_SSL_ENABLED=true" \
  jdeathe/centos-ssh-apache-php:3.3.1
```

##### APACHE_MPM

Using `APACHE_MPM` the Apache MPM can be set. Defaults to `prefork` but `event` or `worker`, is recommended.

```
...
  --env "APACHE_MPM=event" \
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

##### APACHE_SERVER_ALIAS & APACHE_SERVER_NAME

The `APACHE_SERVER_NAME` and `APACHE_SERVER_ALIAS` environmental variables are used to set the VirtualHost `ServerName` and `ServerAlias` values respectively. If the value contains the placeholder `{{HOSTNAME}}` it will be replaced with the system `hostname` value; by default this is the container id but the hostname can be modified using the `--hostname` docker create|run parameter.

In the following example the running container would respond to the host names `app-1.local` or `app-1`.

```
...
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
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

> *Note:* The `base64` command on Mac OSX will encode a file without line breaks by default but if using the command on Linux you need to include use the `-w` option to prevent wrapping lines at 80 characters. i.e. `base64 -w 0 -i {{certificate-path}}`.

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
- [OpenSSL ciphers documentation](https://www.openssl.org/docs/manmaster/man1/ciphers.html).
- [Mozilla Security/Server Side TLS guidance](https://wiki.mozilla.org/Security/Server_Side_TLS).

> *Note:* The value show is using space separated values to allow for readablity in the documentation; this is valid syntax however using the colon separator is the recommended form.

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

Using `PHP_OPTIONS_SESSION_SAVE_HANDLER` and `PHP_OPTIONS_SESSION_SAVE_PATH` together it's possible to configure PHP to use an alternative `session.save_handler` and `session.save_path`. For example if you have a Redis server running on the host `redis-server` on the default port `6379` the following configuration will allow session data to be stored in Redis, allowing session data to be shared between multiple PHP containers.

Using `PHP_OPTIONS_SESSION_NAME` a session name can be defined - otherwise the default name "PHPSESSID" is used.

```
...
  --env "PHP_OPTIONS_SESSION_NAME=APPSESSID" \
  --env "PHP_OPTIONS_SESSION_SAVE_HANDLER=redis" \
  --env "PHP_OPTIONS_SESSION_SAVE_PATH=redis-server:6379" \
...
```

If using the files handler, to set a save path relative to `APACHE_CONTENT_ROOT` the path value should exclude a leading `/`.

```
...
  --env "PHP_OPTIONS_SESSION_SAVE_HANDLER=files" \
  --env "PHP_OPTIONS_SESSION_SAVE_PATH=var/session" \
...
```
