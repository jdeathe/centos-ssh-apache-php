centos-ssh-apache-php
=====================

Docker Image including CentOS-6 6.8 x86_64, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1.

Apache PHP web server, loading only a minimal set of Apache modules by default. Supports custom configuration via environment variables.

## Overview & links

The [Dockerfile](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/Dockerfile) can be used to build a base image that can be run as-is or used as the bases for other more specific builds.

This build of [Apache](https://httpd.apache.org/), (httpd CentOS package), uses the mpm_prefork_module and php5_module modules for handling [PHP](http://php.net/).

Included in the build are the [EPEL](http://fedoraproject.org/wiki/EPEL) and [IUS](https://ius.io/) repositories. Installed packages include [OpenSSH](http://www.openssh.com/portable.html) secure shell, [vim-minimal](http://www.vim.org/), [elinks](http://elinks.or.cz) (for fullstatus support), PHP [APC](http://pecl.php.net/package/APC), PHP [Memcached](http://pecl.php.net/package/memcached) are installed along with python-setuptools, [supervisor](http://supervisord.org/) and [supervisor-stdout](https://github.com/coderanger/supervisor-stdout).

Supervisor is used to start httpd.worker daemon when a docker container based on this image is run. To enable simple viewing of stdout for the service's subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with ```docker logs <docker-container-name>```.

If enabling and configuring SSH access, it is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

### SSH Alternatives

SSH is not required in order to access a terminal for the running container. The simplest method is to use the docker exec command to run bash (or sh) as follows:

```
$ docker exec -it <docker-name-or-id> bash
```

For cases where access to docker exec is not possible the preferred method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/command-keys.md) for details on how to set this up.

## Quick Example

Run up a container named ```apache-php.app-1.1.1``` from the docker image ```jdeathe/centos-ssh-apache-php``` on port 8080 of your docker host.

```
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  --env "APACHE_SERVER_NAME=app-1.local" \
  -v /var/www \
  jdeathe/centos-ssh-apache-php:latest
```

Now point your browser to ```http://<docker-host>:8080``` where "```<docker-host>```" is the host name of your docker server and, if all went well, you should see the "Hello, world!" page.

![Hello World Screen Shot - Chrome](https://raw.github.com/jdeathe/centos-ssh-apache-php/centos-6/images/hello-world-chrome.png)

To be able to access the server using the "app-1.local" domain name you need to add a hosts file entry locally; such that the IP address of the Docker host resolves to the name "app-1.local". Alternatively, you can use the elinks browser installed in the container. Note that because you are using the browser from the container you access the site over port 80.

```
$ docker exec -it apache-php.app-1.1.1 \
  elinks http://app-1.local
```
![Hello World Screen Shot - eLinks](https://raw.github.com/jdeathe/centos-ssh-apache-php/centos-6/images/hello-world-elinks.png)

To verify the container is initialised and running successfully by inspecting the container's logs.

```
$ docker logs apache-php.app-1.1.1
```

The Apache data is persistent across container restarts by setting the data directory ```/var/www``` as a data volume. No name or docker_host path was specified so Docker will give it a unique name and store it in ```/var/lib/docker/volumes/```; to find out where the data is stored on the Docker host you can use ```docker inspect```.

```
$ docker inspect \
  --format '{{ json (index .Mounts 0).Source }}' \
  apache-php.app-1.1.1
```

On first run, the bootstrap script, ([/usr/sbin/httpd-bootstrap](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/usr/sbin/httpd-bootstrap)), will check if the DocumentRoot directory is empty and, if so, will populate it with the example app scripts and app specific configuration files.

The ```apachectl``` command can be accessed as follows.

```
$ docker exec -it apache-php.app-1.1.1 apachectl -h
```

## Instructions

### Running

To run the a docker container from this image you can use the included [run.sh](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.sh) and [run.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.conf) scripts. The helper script will stop any running container of the same name, remove it and run a new daemonised container on an unspecified host port. Alternatively you can use the following methods to make the http service available on ports 8080 of the docker host.

#### Using environment variables

```
$ docker stop apache-php.app-1.1.1 && \
  docker rm apache-php.app-1.1.1
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  --env "APACHE_CONTENT_ROOT=/var/www/app-1" \
  --env "APACHE_CUSTOM_LOG_FORMAT=combined" \
  --env "APACHE_CUSTOM_LOG_LOCATION=/var/www/app-1/var/log/apache_access_log" \
  --env "APACHE_ERROR_LOG_LOCATION=/var/www/app-1/var/log/apache_error_log" \
  --env "APACHE_ERROR_LOG_LEVEL=warn" \
  --env "APACHE_EXTENDED_STATUS_ENABLED=false" \
  --env "APACHE_LOAD_MODULES=authz_user_module log_config_module expires_module deflate_module headers_module setenvif_module mime_module status_module dir_module alias_module rewrite_module" \
  --env "APACHE_MOD_SSL_ENABLED=false" \
  --env "APACHE_RUN_GROUP=www-app" \
  --env "APACHE_RUN_USER=www-app" \
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "APACHE_SYSTEM_USER=app" \
  --env "PHP_OPTIONS_DATE_TIMEZONE=UTC" \
  --env "SERVICE_UID=app-1.1.1" \
  -v volume-data.apache-php.app-1.1.1:/var/www \
  jdeathe/centos-ssh-apache-php:latest
```

#### Environment Variables

##### APACHE_SERVER_NAME & APACHE_SERVER_ALIAS

The ```APACHE_SERVER_NAME``` and ```APACHE_SERVER_ALIAS``` environmental variables are used to set the VirtualHost ```ServerName``` and ```ServerAlias``` values respectively. In the following example the running container would respond to the host names ```app-1.local``` or ```app-1```:

```
...
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
...
```

##### APACHE_CONTENT_ROOT

The home directory of the service user and parent directory of the Apache DocumentRoot is /var/www/app by default but can be changed if necessary using the ```APACHE_CONTENT_ROOT``` environment variable.

```
...
  --env "APACHE_CONTENT_ROOT=/var/www/app-1" \
...
```

from your browser you can then access it with ```http://app-1.local:8080``` assuming you have the IP address of your docker mapped to the hostname using your DNS server or a local hosts entry.

##### APACHE_CUSTOM_LOG_LOCATION & APACHE_CUSTOM_LOG_FORMAT

The Apache CustomLog can be defined using ```APACHE_CUSTOM_LOG_LOCATION``` to set a file | pipe location and ```APACHE_CUSTOM_LOG_FORMAT``` to specify the required LogFormat nickname.

```
...
  --env "APACHE_CUSTOM_LOG_LOCATION=/var/log/httpd/access_log" \
  --env "APACHE_CUSTOM_LOG_FORMAT=common" \
...
```

##### APACHE_ERROR_LOG_LOCATION & APACHE_ERROR_LOG_LEVEL

The Apache ErrorLog can be defined using ```APACHE_ERROR_LOG_LOCATION``` to set a file | pipe location and ```APACHE_ERROR_LOG_LEVEL``` to specify the required LogLevel value.

```
...
  --env "APACHE_CUSTOM_LOG_LOCATION=/var/log/httpd/error_log" \
  --env "APACHE_CUSTOM_LOG_FORMAT=error" \
...
```

##### APACHE_EXTENDED_STATUS_ENABLED

The variable ```APACHE_EXTENDED_STATUS_ENABLED``` allows you to turn ExtendedStatus on. It is turned off by default as it has an impact on the server's performance but with it enabled you can gather more statistics.

```
...
  --env "APACHE_EXTENDED_STATUS_ENABLED=true"
...
```

You can view the output from Apache server-status either using the elinks browser from onboard the container or by using `watch` and `curl` to monitor status over time - the following command shows the server-status updated at a 1 second interval.

```
$ docker exec -it apache-php.app-1.1.1 \
  env TERM=xterm \
  watch -n 1 \
  -d "curl -s http://app-1/server-status?auto"
```

##### APACHE_LOAD_MODULES

The variable ```APACHE_LOAD_MODULES``` defines all Apache modules to be loaded from */etc/httpd/conf/http.conf*. The default is the minimum required so you may need to add more as necessary. To add the "mod\_rewrite" Apache Module you would add it's identifier ```rewrite_module``` to the array as follows.

```
...
  --env "APACHE_LOAD_MODULES=authz_user_module log_config_module expires_module deflate_module headers_module setenvif_module mime_module status_module dir_module alias_module rewrite_module"
...
```

##### APACHE_MOD_SSL_ENABLED

By default SSL support is disabled but a second port, (mapped to 8443), is available for traffic that has been been through upstream SSL termination (SSL Offloading). If you want the container to support SSL directly then set ```APACHE_MOD_SSL_ENABLED=true``` this will then generate a self signed certificate and will update Apache to accept traffic on port 443.

```
$ docker stop apache-php.app-1.1.1 && \
  docker rm apache-php.app-1.1.1
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  -p 8580:443 \
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "APACHE_MOD_SSL_ENABLED=true" \
  --env "PHP_OPTIONS_DATE_TIMEZONE=UTC" \
  --env "SERVICE_UID=app-1.1.1" \
  -v volume-data.apache-php.app-1.1.1:/var/www \
  jdeathe/centos-ssh-apache-php:latest
```

##### APACHE_RUN_USER & APACHE_RUN_GROUP

The Apache process is run by the User and Group defined by ```APACHE_RUN_USER``` and ```APACHE_RUN_GROUP``` respectively.

```
...
  --env "APACHE_RUN_GROUP=www-app" \
  --env "APACHE_RUN_USER=www-app" \
...
```

##### APACHE_PUBLIC_DIRECTORY

The public directory is relative to the ```APACHE_CONTENT_ROOT``` and together they form the Apache DocumentRoot path. The default value is `public_html` and should not be changed unless changes are made to the source of the app to include an alternative public directory such as `web` or `public`.

```
...
  --env "APACHE_PUBLIC_DIRECTORY=web" \
...
```

##### APACHE_SYSTEM_USER

Use the ```APACHE_SYSTEM_USER``` environment variable to define a custom service username.

```
...
  --env "APACHE_SYSTEM_USER=app-1" \
...
```

##### PHP_OPTIONS_DATE_TIMEZONE

The default timezone for the container, and the PHP app, is UTC however the operator can set an appropriate timezone using the ```PHP_OPTIONS_DATE_TIMEZONE``` variable. The value should be a timezone identifier, like UTC or Europe/London. The list of valid identifiers is available in the PHP [List of Supported Timezones](http://php.net/manual/en/timezones.php).

To set the timezone for the UK and account for British Summer Time you would use:

```
...
  --env "PHP_OPTIONS_DATE_TIMEZONE=Europe/London" \
...
```

##### SERVICE_UID

The ```SERVICE_UID``` environmental variable is used to set a response header named ```X-Service-Uid``` that lets you identify the container that is serving the content. This is useful when you have many containers running on a single host using different ports or if you are running a cluster and need to identify which host the content is served from. If the value contains the placeholder `{{HOSTNAME}}` it will be replaced with the system `hostname` value; by default this is the container id but the hostname can be modified using the `--hostname` docker create|run parameter.

```
...
  --env "SERVICE_UID={{HOSTNAME}}" \
...
```
