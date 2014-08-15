centos-ssh-apache-php
=====================

Docker Image including CentOS-6, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1, Composer.

The Dockerfile can be used to build a base image that can be run as-is or used as the bases for other more specific builds.

Included in the build is the EPEL repository and SSH, vi, elinks (for fullstatus support), APC, Memcache and Composer are installed along with python-pip, supervisor and supervisor-stdout.

[Supervisor](http://supervisord.org/) is used to start httpd (and optionally the sshd) daemon when a docker container based on this image is run. To enable simple viewing of stdout for the sshd subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs <docker-container-name>`.

SSH is not required in order to access a terminal for the running container the prefered method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh-apache-php/blob/master/command-keys.md) for details on how to set this up.

If enabling and configuring SSH access, it is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

## Quick Example

Run up a container named 'apache-php.app-1.1.1' from the docker image 'jdeathe/centos-ssh-apache-php' on port 2020 of your docker host.

```
$ docker run -d \
  apache-php.app-1.1.1 \
  -p 8080:80 \
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
