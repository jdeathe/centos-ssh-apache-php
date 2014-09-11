centos-ssh-apache-php
=====================

Docker Image including CentOS-6, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1, Composer.

The Dockerfile can be used to build a base image that can be run as-is or used as the bases for other more specific builds.

Included in the build is the EPEL repository and SSH, vi, elinks (for fullstatus support), APC, Memcache and Composer are installed along with python-pip, supervisor and supervisor-stdout.

[Supervisor](http://supervisord.org/) is used to start httpd (and optionally the sshd) daemon when a docker container based on this image is run. To enable simple viewing of stdout for the sshd subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs <docker-container-name>`.

SSH is not required in order to access a terminal for the running container the prefered method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/command-keys.md) for details on how to set this up.

If enabling and configuring SSH access, it is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

## Quick Example

Run up a container named ```apache-php.app-1.1.1``` from the docker image ```jdeathe/centos-ssh-apache-php``` on port 8080 of your docker host.

```
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  --env SERVICE_UNIT_APP_GROUP=app-1 \
  --env SERVICE_UNIT_LOCAL_ID=1 \
  --env SERVICE_UNIT_INSTANCE=1 \
  --env APACHE_SERVER_NAME=app-1.local \
  --env APACHE_SERVER_ALIAS=app-1 \
  --env DATE_TIMEZONE=UTC \
  -v /var/services-data/apache-php/app-1:/var/www/app \
  jdeathe/centos-ssh-apache-php:latest
```

Now point your browser to ```http://<docker-host>:8080``` where "```<docker-host>```" is the host name of your docker server and, if all went well, you should see the "Hello, world!" page.

![Hello World Screen Shot](https://raw.github.com/jdeathe/centos-ssh-apache-php/centos-6/images/hello-world.png)

## Instructions

### (Optional) Configuration Data Volume

Create a "data volume" for configuration, this allows you to share the same configuration between multiple docker containers and, by mounting a host directory into the data volume you can override the default configuration files provided.

Make a directory on the docker host for storing container configuration files. This directory needs to contain everything from the directory [etc/services-config](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/etc/services-config)

```
$ mkdir -p /etc/services-config/apache-php.app-1.1.1
```

Create the data volume, mounting our docker host's configuration directory to */etc/services-config/ssh* in the docker container. Docker will pull the busybox:latest image if you don't already have it available locally.

```
$ docker run \
  --name volume-config.apache-php.app-1.1.1 \
  -v /etc/services-config/ssh.pool-1:/etc/services-config/ssh \
  -v /etc/services-config/apache-php.app-1.1.1/supervisor:/etc/services-config/supervisor \
  -v /etc/services-config/apache-php.app-1.1.1/httpd:/etc/services-config/httpd \
  -v /etc/services-config/apache-php.app-1.1.1/ssl/certs:/etc/services-config/ssl/certs \
  -v /etc/services-config/apache-php.app-1.1.1/ssl/private:/etc/services-config/ssl/private \
  busybox:latest \
  /bin/true
```

### Running

To run the a docker container from this image you can use the included [run.sh](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.sh) and [run.conf](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.conf) scripts. The helper script will stop any running container of the same name, remove it and run a new daemonised container on an unspecified host port. Alternatively you can use the following.

```
$ docker stop apache-php.app-1.1.1 && \
  docker rm apache-php.app-1.1.1
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  -p 8580:8443 \
  --env SERVICE_UNIT_INSTANCE=app-1 \
  --env SERVICE_UNIT_LOCAL_ID=1 \
  --env SERVICE_UNIT_INSTANCE=1 \
  --env APACHE_SERVER_NAME=app-1.local \
  --env APACHE_SERVER_ALIAS=app-1 \
  --env DATE_TIMEZONE=UTC \
  --volumes-from volume-config.apache-php.app-1.1.1 \
  -v /var/services-data/apache-php/app-1:/var/www/app \
  jdeathe/centos-ssh-apache-php:latest
```

Now you can verify it is initialised and running successfully by inspecting the container's logs

```
$ docker logs apache-php.app-1.1.1
```

The output of the logs should show the Apache modules being loaded and auto-generated password for the Apache user and group, (if not try again after a few seconds).

#### Runtime Environment Variables

There are several environmental variables defined at runtime these allow the operator to customise the running container which may become necessary when running several on the same docker host, when clustering docker hosts or to simply set the timezone.

##### 1. SERVICE_UNIT*

The ```SERVICE_UNIT``` environmental variables are used to set a response header named ```X-Service-Uid``` that lets you identify the container that is serving the content. This is useful when you have many containers running on a single host using differnt ports (i.e with differnet ```SERVICE_UNIT_LOCAL_ID``` values) or if you are running a cluster and need to identify which host the content is served from (i.e with different ```SERVICE_UNIT_INSTANCE``` values). The three values should map to the last 3 dotted values of the container name; in our case that is "app-1.1.1"

```
...
  --env SERVICE_UNIT_APP_GROUP=app-1 \
  --env SERVICE_UNIT_LOCAL_ID=1 \
  --env SERVICE_UNIT_INSTANCE=1 \
...
```

##### 2. APACHE_SERVER*

The ```APACHE_SERVER_NAME``` and ```APACHE_SERVER_ALIAS``` environmental variables are used to set the VirtualHost ```ServerName``` and ```ServerAlias``` values respectively. In the following example the running container would respond to the host names ```app-1.local``` or ```app-1```:

```
...
  --env APACHE_SERVER_NAME=app-1.local \
  --env APACHE_SERVER_ALIAS=app-1 \
...
```

from your browser you can then access it with ```http://app-1.local:8080``` assuming you have the IP address of your docker mapped to the hostname using your DNS server or a local hosts entry.

##### 3. DATE_TIMEZONE

The default timezone for the container, and the PHP app, is UTC however the operator can set an appropriate timezone using the ```DATE_TIMEZONE``` variable. The value should be a timezone identifier, like UTC or Europe/London. The list of valid identifiers is available in the PHP [List of Supported Timezones](http://php.net/manual/en/timezones.php).

To set the timezone for the UK and account for British Summer Time you would use:

```
...
  --env DATE_TIMEZONE=Europe/London \
...
```

### Custom Configuration

If using the optional data volume for container configuration you are able to customise the configuration. In the following examples your custom docker configuration files should be located on your local host within a "config" directory relative to your working directory - i.e: *./config/apache-php.app-1.1.1*

#### services-config/httpd/apache-bootstrap.conf

The bootstrap script initialises the app. It sets up the Apache service user + group, generates passwords, enables Apache modules and adds/removes SSL support.

##### 1. Service User

Use the ```SERVICE_USER*``` variables in your custom apache-bootstrap.conf file to override this and to also define a custom username and/or group.

```
SERVICE_USER=apacheUser
SERVICE_USER_GROUP=apacheGroup
SERVICE_USER_PASSWORD=userPassword123
SERVICE_USER_GROUP_PASSWORD=userGroupPassword123
```

##### 2. Apache Modules

The variable ```APACHE_LOAD_MODULES``` defines all Apache modules to be loaded from */etc/httpd/conf/http.conf*. The default is the minimum required so you may need to add more as necessary. To add the "mod\_rewrite" Apache Module you would add it's identifier ```rewrite_module``` to the array as follows.

```
APACHE_LOAD_MODULES="
    authz_user_module
    log_config_module
    expires_module
    deflate_module
    headers_module
    setenvif_module
    mime_module
    status_module
    dir_module
    alias_module
    rewrite_module
"
```

##### 3. SSL Support

By default SSL support is disabled but a second port, (mapped to 8443), is available for traffic that has been been through upstream SSL termination (SSL Offloading). If you want the container to support SSL directly then set ```APACHE_MOD_SSL_ENABLED=true``` this will then generate a self signed certificate and will update Apache to accept traffic on port 443.

*Note:* The included helper script [run.sh](https://github.com/jdeathe/centos-ssh-apache-php/blob/centos-6/run.sh) will automatically map the docker host port 8580 to 443 but if you are running docker manually can use the following.

```
$ docker stop apache-php.app-1.1.1 && \
  docker rm apache-php.app-1.1.1
$ docker run -d \
  --name apache-php.app-1.1.1 \
  -p 8080:80 \
  -p 8580:443 \
  --env SERVICE_UNIT_APP_GROUP=app-1 \
  --env SERVICE_UNIT_LOCAL_ID=1 \
  --env SERVICE_UNIT_INSTANCE=1 \
  --env APACHE_SERVER_NAME=app-1.local \
  --env APACHE_SERVER_ALIAS=app-1 \
  --env DATE_TIMEZONE=UTC \
  --volumes-from volume-config.apache-php.app-1.1.1 \
  -v /var/services-data/apache-php/app-1:/var/www/app \
  jdeathe/centos-ssh-apache-php:latest
```

#### services-config/ssl/certs/localhost.crt

You may need to override the default auto-generated self signed certificate. To do this you can add the SSLCertificateFile to your config directory using the filename ```localhost.crt``` for example:

```
./config/services-config/ssl/certs/localhost.crt
```

*Note:* You must also specify the associated SSLCertificateKeyFile in this case.

#### services-config/ssl/private/localhost.key

To override the SSLCertificateKeyFile add it to your config directory using the filename ```localhost.key``` for example:

```
./config/services-config/ssl/private/localhost.key
```

*Note:* You must also specify the associated SSLCertificateFile in this case.

#### services-config/supervisor/supervisord.conf

The supervisor service's configuration can also be overriden by editing the custom supervisord.conf file. It shouldn't be necessary to change the existing configuration here but you could include more [program:x] sections to run additional commands at startup.

### DocumentRoot Data Directory

In the previous example Docker run commands we mapped the Docker host directory ```/var/services-data/apache-php/app-1``` to ```/var/www/app``` in the Docker container, where ```/var/services-data/``` is the directory used to store persistent files and the subdirectory is used by an individual app's named container(s), ```apache-php.app-1.1.1```, in the previous examples.

On first run, the bootstrap script, ([/etc/apache-bootstrap](https://github.com/jdeathe/centos-ssh-apache-php/blob/master/etc/apache-bootstrap)), will check if the DocumentRoot directory is empty and, if so, will poplate it with the example app scripts and VirtualHost configuration files. If you place your own app in this directory it will not be overwritten but you must ensure to include at least a vhost.conf file and, if enabling SSL a vhost-ssl.conf file too.
