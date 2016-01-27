centos-ssh-apache-php
=====================

Docker Image including CentOS-6 6.7 x86_64, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1.

Apache PHP web server, loading only a minimal set of Apache modules by default. Supports custom configuration via environment variables and/or a configuration data volume.

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
  --env "SERVICE_UNIT_APP_GROUP=app-1" \
  --env "SERVICE_UNIT_LOCAL_ID=1" \
  --env "SERVICE_UNIT_INSTANCE=1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "DATE_TIMEZONE=UTC" \
  -v /var/www/app \
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

The Apache data is persistent across container restarts by setting the data directory ```/var/www/app``` as a data volume. No name or docker_host path was specified so Docker will give it a unique name and store it in ```/var/lib/docker/volumes/```; to find out where the data is stored on the Docker host you can use ```docker inspect```.

```
$ docker inspect \
  --format '{{ json (index .Mounts 0).Source }}' \
  apache-php.app-1.1.1
```

On first run, the bootstrap script, ([/etc/apache-bootstrap](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/apache-bootstrap)), will check if the DocumentRoot directory is empty and, if so, will populate it with the example app scripts and VirtualHost configuration files. If you place your own app in this directory it will not be overwritten but you must ensure to include at least a vhost.conf file and, if enabling SSL a vhost-ssl.conf file too.

The ```apachectl``` command can be accessed as follows.

```
$ docker exec -it apache-php.app-1.1.1 apachectl -h
```

## Instructions

### (Optional) Configuration Data Volume

A configuration "data volume" allows you to share the same configuration files between multiple docker containers. Docker mounts a host directory into the data volume allowing you to edit the default configuration files and have those changes persist.

Each service that requires a common set of configuration files could use a single Configuration Volume as illustrated in the following diagram:

```
+---------------------------------------------------+
|                (Docker Host system)               |
|                                                   |
| /var/lib/docker/volumes/<volume-name>/_data       |
|                         +                         |
|                         |                         |
|            +============*===========+             |
|            |  Configuration Volume  |             |
|            |    Service Container   |             |
|            +============*===========+             |
|                         |                         |
|         +---------------*---------------+         |
|         |               |               |         |
|   +=====*=====+   +=====*=====+   +=====*=====+   |
|   |  Service  |   |  Service  |   |  Service  |   |
|   | Container |   | Container |   | Container |   |
|   |    (1)    |   |    (2)    |   |    (n)    |   |
|   +===========+   +===========+   +===========+   |
+---------------------------------------------------+
```

#### Standard data volume container

Naming of the container's volume is optional, it is possible to leave the naming up to Docker by simply specifying the container path only.

```
$ docker run \
  --name volume-config.apache-php.app-1.1.1 \
  -v /etc/services-config \
  jdeathe/centos-ssh-apache-php:latest \
  /bin/true
```

To identify the docker host directory path to the volume within the container ```volume-config.apache-php.app-1.1.1``` you can use ```docker inspect``` to view the Mounts.

```
$ docker inspect \
  --format '{{ json (index .Mounts 0).Source }}' \
  volume-config.apache-php.app-1.1.1
```

#### Named data volume container

To create a named data volume, mounting our docker host's configuration directory /var/lib/docker/volumes/volume-config.apache-php.app-1.1.1 to /etc/services-config in the docker container use the following run command. Note that we use the same image as for the application container to reduce the number of images/layers required.

```
$ docker run \
  --name volume-config.apache-php.app-1.1.1 \
  -v volume-config.apache-php.app-1.1.1:/etc/services-config \
  jdeathe/centos-ssh-apache-php:latest \
  /bin/true
```

##### Populating Named configuration data volumes  
When using named volumes the directory path from the docker host mounts the path on the container so we need to upload the configuration files. The simplest method of achieving this is to upload the contents of the [etc/services-config](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config/) directory using ```docker cp```.

```
$ docker cp \
  ./etc/services-config/. \
  volume-config.apache-php.app-1.1.1:/etc/services-config
```

If you don't have a copy of the required configuration files locally you can run a temporary container as the source of the configuration files and use `docker cp` to stream the files into the named data volume container.

```
$ docker run -d \
  --name apache-php.tmp \
  jdeathe/centos-ssh-apache-php:latest \
  /bin/sh -c 'while true; do echo -ne .; sleep 1; done';
  && docker cp \
  apache-php.tmp:/etc/services-config/. - | \
  docker cp - \
  volume-config.apache-php.app-1.1.1:/etc/services-config
  && docker rm -f apache-php.tmp
```

#### Editing configuration

To make changes to the configuration files you need a running container that uses the volumes from the configuration volume. To edit a single file you could use the following, where <path_to_file> can be one of the [required configuration files](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/README.md#required-configuration-files), or you could run a ```bash``` shell and then make the changes required using ```vi```. On exiting the container it will be removed since we specify the ```--rm``` parameter.

```
$ docker run --rm -it \
  --volumes-from volume-config.apache-php.app-1.1.1 \
  jdeathe/centos-ssh-apache-php:latest \
  vi /etc/services-config/<path_to_file>
```

##### Required configuration files

The following configuration files are required to run the application container and should be located in the directory /etc/services-config/.

- [httpd/conf/httpd.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config/httpd/conf/httpd.conf)
- [httpd/conf.d/php.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config/httpd/conf.d/php.conf)
- [httpd/conf.d/ssl.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config/httpd/conf.d/ssl.conf)
- [supervisor/supervisord.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config/supervisor/supervisord.conf)

### Running

To run the a docker container from this image you can use the included [run.sh](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.sh) and [run.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.conf) scripts. The helper script will stop any running container of the same name, remove it and run a new daemonised container on an unspecified host port. Alternatively you can use the following methods to make the http service available on ports 8080 of the docker host.

#### Using environment variables

*Note:* Settings applied by environment variables will override those set within configuration volumes from release 1.3.1. Existing installations that use the apache-bootstrap.conf saved on a configuration "data" volume will not allow override by the environment variables. Also apache-bootstrap.conf can be updated to prevent the value being replaced by that set using the environment variable.

```
$ docker stop apache-php.app-1.1.1 && \
  docker rm apache-php.app-1.1.1
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  --env "SERVICE_UNIT_INSTANCE=app-1" \
  --env "SERVICE_UNIT_LOCAL_ID=1" \
  --env "SERVICE_UNIT_INSTANCE=1" \
  --env "APACHE_EXTENDED_STATUS_ENABLED=false" \
  --env "APACHE_LOAD_MODULES=authz_user_module log_config_module expires_module deflate_module headers_module setenvif_module mime_module status_module dir_module alias_module rewrite_module" \
  --env "APACHE_MOD_SSL_ENABLED=false" \
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "APP_HOME_DIR=/var/www/app-1" \
  --env "DATE_TIMEZONE=UTC" \
  --env "SERVICE_USER=app" \
  --env "SERVICE_USER_GROUP=app-www" \
  --env "SERVICE_USER_PASSWORD=" \
  -v volume-data.apache-php.app-1.1.1:/var/www/app-1 \
  jdeathe/centos-ssh-apache-php:latest
```

#### Using configuration volume

The following example uses the settings from the optonal configuration volume volume-config.apache-php.app-1.1.1 and maps a data volume for persistent storage of the Apache app data on the docker host.

```
$ docker stop apache-php.app-1.1.1 && \
  docker rm apache-php.app-1.1.1
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  --env "SERVICE_UNIT_INSTANCE=app-1" \
  --env "SERVICE_UNIT_LOCAL_ID=1" \
  --env "SERVICE_UNIT_INSTANCE=1" \
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "DATE_TIMEZONE=UTC" \
  --volumes-from volume-config.apache-php.app-1.1.1 \
  -v volume-data.apache-php.app-1.1.1:/var/www/app \
  jdeathe/centos-ssh-apache-php:latest
```

Now you can verify it is initialised and running successfully by inspecting the container's logs

```
$ docker logs apache-php.app-1.1.1
```

The output of the logs should show the Apache modules being loaded and auto-generated password for the Apache user and group, (if not try again after a few seconds).

#### Runtime Environment Variables

There are several environmental variables defined at runtime these allow the operator to customise the running container which may become necessary when running several on the same docker host, when clustering docker hosts or to simply set the timezone.

##### 1. SERVICE_UNIT_INSTANCE, SERVICE_UNIT_LOCAL_ID & SERVICE_UNIT_INSTANCE

The ```SERVICE_UNIT_INSTANCE```, ```SERVICE_UNIT_LOCAL_ID``` and ```SERVICE_UNIT_INSTANCE``` environmental variables are used to set a response header named ```X-Service-Uid``` that lets you identify the container that is serving the content. This is useful when you have many containers running on a single host using different ports (i.e with different ```SERVICE_UNIT_LOCAL_ID``` values) or if you are running a cluster and need to identify which host the content is served from (i.e with different ```SERVICE_UNIT_INSTANCE``` values). The three values should map to the last 3 dotted values of the container name; in our case that is "app-1.1.1"

```
...
  --env "SERVICE_UNIT_APP_GROUP=app-1" \
  --env "SERVICE_UNIT_LOCAL_ID=1" \
  --env "SERVICE_UNIT_INSTANCE=1" \
...
```

##### 2. APACHE_SERVER_NAME & APACHE_SERVER_ALIAS

The ```APACHE_SERVER_NAME``` and ```APACHE_SERVER_ALIAS``` environmental variables are used to set the VirtualHost ```ServerName``` and ```ServerAlias``` values respectively. In the following example the running container would respond to the host names ```app-1.local``` or ```app-1```:

```
...
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
...
```

from your browser you can then access it with ```http://app-1.local:8080``` assuming you have the IP address of your docker mapped to the hostname using your DNS server or a local hosts entry.

##### 3. APACHE_EXTENDED_STATUS_ENABLED

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
  watch -n 10 \
  -d "curl -s http://app-1/_httpdstatus?auto"
```

##### 4. APACHE_LOAD_MODULES

The variable ```APACHE_LOAD_MODULES``` defines all Apache modules to be loaded from */etc/httpd/conf/http.conf*. The default is the minimum required so you may need to add more as necessary. To add the "mod\_rewrite" Apache Module you would add it's identifier ```rewrite_module``` to the array as follows.

```
...
  --env "APACHE_LOAD_MODULES=authz_user_module log_config_module expires_module deflate_module headers_module setenvif_module mime_module status_module dir_module alias_module rewrite_module"
...
```

##### 5. APACHE_MOD_SSL_ENABLED

By default SSL support is disabled but a second port, (mapped to 8443), is available for traffic that has been been through upstream SSL termination (SSL Offloading). If you want the container to support SSL directly then set ```APACHE_MOD_SSL_ENABLED=true``` this will then generate a self signed certificate and will update Apache to accept traffic on port 443.

*Note:* The included helper script [run.sh](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.sh) will automatically map the docker host port 8580 to 443 but if you are running docker manually can use the following.

```
$ docker stop apache-php.app-1.1.1 && \
  docker rm apache-php.app-1.1.1
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  -p 8580:443 \
  --env "SERVICE_UNIT_APP_GROUP=app-1" \
  --env "SERVICE_UNIT_LOCAL_ID=1" \
  --env "SERVICE_UNIT_INSTANCE=1" \
  --env "APACHE_SERVER_ALIAS=app-1" \
  --env "APACHE_SERVER_NAME=app-1.local" \
  --env "APACHE_MOD_SSL_ENABLED=true" \
  --env "DATE_TIMEZONE=UTC" \
  -v volume-data.apache-php.app-1.1.1:/var/www/app \
  jdeathe/centos-ssh-apache-php:latest
```

##### 6. APP_HOME_DIR

The home directory of the service user and parent directory of the Apache DocumentRoot is  /var/www/app by default but can be changed if necessary using the ```APP_HOME_DIR``` environment variable. It is also necessary to change the target of the data volume mapping accordingly as in the following example where /var/www/app-1 is used.

```
...
  --env "APP_HOME_DIR=/var/www/app-1" \
  -v volume-data.apache-php.app-1.1.1:/var/www/app-1 \
...
```

##### 7. DATE_TIMEZONE

The default timezone for the container, and the PHP app, is UTC however the operator can set an appropriate timezone using the ```DATE_TIMEZONE``` variable. The value should be a timezone identifier, like UTC or Europe/London. The list of valid identifiers is available in the PHP [List of Supported Timezones](http://php.net/manual/en/timezones.php).

To set the timezone for the UK and account for British Summer Time you would use:

```
...
  --env "DATE_TIMEZONE=Europe/London" \
...
```

##### 8. SERVICE_USER, SERVICE_USER_GROUP & SERVICE_USER_PASSWORD

Use the ```SERVICE_USER```, ```SERVICE_USER_GROUP``` and ```SERVICE_USER_PASSWORD``` environment variables to define a custom service username, group and password respectively. If the password is left an empty string then it is automatically generated on first run which is the default.

```
...
  --env "SERVICE_USER=apacheUser" \
  --env "SERVICE_USER_GROUP=apacheGroup" \
  --env "SERVICE_USER_PASSWORD=userPassword123" \
...
```

### Custom Configuration

If using the optional data volume for container configuration you are able to customise the configuration. In the following examples your custom docker configuration files should be located on the Docker host under the directory ```/var/lib/docker/volumes/<volume-name>/``` where ```<container-name>``` should match the applicable container name such as "apache-php.app-1.1.1" if using named volumes or will be an ID generated automatically by Docker. To identify the correct path on the Docker host use the ```docker inspect``` command.

#### [httpd/apache-bootstrap.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config/httpd/apache-bootstrap.conf)

The bootstrap script initialises the app. It sets up the Apache service user + group, generates passwords, enables Apache modules and adds/removes SSL support.

#### ssl/certs/localhost.crt

You may need to override the default auto-generated self signed certificate. To do this you can add the SSLCertificateFile to the Docker hosts directory using the filename ```localhost.crt``` for example:

```
/etc/services-config/apache-php.app-1.1.1/ssl/certs/localhost.crt
```

*Note:* You must also specify the associated SSLCertificateKeyFile in this case.

#### ssl/private/localhost.key

To override the SSLCertificateKeyFile add it to your config directory using the filename ```localhost.key``` for example:

```
/etc/services-config/apache-php.app-1.1.1/ssl/certs/localhost.key
```

*Note:* You must also specify the associated SSLCertificateFile in this case.

#### [supervisor/supervisord.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config/supervisor/supervisord.conf)

The supervisor service's configuration can also be overridden by editing the custom supervisord.conf file. It shouldn't be necessary to change the existing configuration here but you could include more [program:x] sections to run additional commands at startup.
