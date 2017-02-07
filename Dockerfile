# =============================================================================
# jdeathe/centos-ssh-apache-php
#
# CentOS-6, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1
#
# =============================================================================
FROM jdeathe/centos-ssh:1.7.5

MAINTAINER James Deathe <james.deathe@gmail.com>

# Use the form ([{fqdn}-]{package-name}|[{fqdn}-]{provider-name})
ARG PACKAGE_NAME="app"
ARG PACKAGE_PATH="/opt/${PACKAGE_NAME}"
ARG PACKAGE_RELEASE_VERSION="0.4.0"

# -----------------------------------------------------------------------------
# Base Apache, PHP
# -----------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& yum --setopt=tsflags=nodocs -y install \
		elinks-0.12-0.21.pre5.el6_3 \
		httpd-2.2.15-56.el6.centos.3 \
		mod_ssl-2.2.15-56.el6.centos.3 \
		php-5.3.3-48.el6_8 \
		php-cli-5.3.3-48.el6_8 \
		php-zts-5.3.3-48.el6_8 \
		php-pecl-apc-3.1.9-2.el6 \
		php-pecl-memcached-1.0.0-1.el6 \
	&& yum versionlock add \
		elinks \
		httpd \
		mod_ssl \
		php* \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# Global Apache configuration changes
# - Disable Apache directory indexes.
# - Disable Apache language based content negotiation.
# - Enable ServerStatus access via /server-status to local client.
# -----------------------------------------------------------------------------
RUN sed -i \
		-e 's~^KeepAlive .*$~KeepAlive On~g' \
		-e 's~^MaxKeepAliveRequests .*$~MaxKeepAliveRequests 200~g' \
		-e 's~^KeepAliveTimeout .*$~KeepAliveTimeout 2~g' \
		-e 's~^ServerSignature On$~ServerSignature Off~g' \
		-e 's~^ServerTokens OS$~ServerTokens Prod~g' \
		-e 's~^NameVirtualHost \(.*\)$~#NameVirtualHost \1~g' \
		-e 's~^User .*$~User ${APACHE_RUN_USER}~g' \
		-e 's~^Group .*$~Group ${APACHE_RUN_GROUP}~g' \
		-e 's~^DocumentRoot \(.*\)$~#DocumentRoot \1~g' \
		-e 's~^IndexOptions \(.*\)$~#IndexOptions \1~g' \
		-e 's~^IndexIgnore \(.*\)$~#IndexIgnore \1~g' \
		-e 's~^AddIconByEncoding \(.*\)$~#AddIconByEncoding \1~g' \
		-e 's~^AddIconByType \(.*\)$~#AddIconByType \1~g' \
		-e 's~^AddIcon \(.*\)$~#AddIcon \1~g' \
		-e 's~^DefaultIcon \(.*\)$~#DefaultIcon \1~g' \
		-e 's~^ReadmeName \(.*\)$~#ReadmeName \1~g' \
		-e 's~^HeaderName \(.*\)$~#HeaderName \1~g' \
		-e 's~^LanguagePriority \(.*\)$~#LanguagePriority \1~g' \
		-e 's~^ForceLanguagePriority \(.*\)$~#ForceLanguagePriority \1~g' \
		-e 's~^AddLanguage \(.*\)$~#AddLanguage \1~g' \
		-e '/#<Location \/server-status>/,/#<\/Location>/ s~^#~~' \
		-e '/<Location \/server-status>/,/<\/Location>/ s~Allow from .example.com~Allow from localhost 127.0.0.1~' \
		/etc/httpd/conf/httpd.conf \
	&& { \
			echo ''; \
			echo '#'; \
			echo '# Custom configuration'; \
			echo '#'; \
			echo 'LogFormat \'; \
			echo '  "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" \'; \
			echo '  forwarded_for_combined'; \
			echo 'Include /etc/services-config/httpd/conf.d/*.conf'; \
			echo 'Listen 8443'; \
			echo 'Options -Indexes'; \
			echo 'TraceEnable Off'; \
			echo 'UseCanonicalName On'; \
			echo 'UseCanonicalPhysicalPort On'; \
		} >> /etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable all Apache modules and enable the minimum
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^\(LoadModule .*\)$~#\1~g' \
	-e 's~^#\(LoadModule mime_module .*\)$~\1~' \
	-e 's~^#\(LoadModule log_config_module .*\)$~\1~' \
	-e 's~^#\(LoadModule setenvif_module .*\)$~\1~' \
	-e 's~^#\(LoadModule status_module .*\)$~\1~' \
	-e 's~^#\(LoadModule authz_host_module .*\)$~\1~' \
	-e 's~^#\(LoadModule dir_module .*\)$~\1~' \
	-e 's~^#\(LoadModule alias_module .*\)$~\1~' \
	-e 's~^#\(LoadModule expires_module .*\)$~\1~' \
	-e 's~^#\(LoadModule deflate_module .*\)$~\1~' \
	-e 's~^#\(LoadModule headers_module .*\)$~\1~' \
	-e 's~^#\(LoadModule alias_module .*\)$~\1~' \
	-e 's~^#\(LoadModule version_module .*\)$~\1\n#LoadModule reqtimeout_module modules/mod_reqtimeout.so~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable SSL + the default SSL Virtual Host
# -----------------------------------------------------------------------------
RUN sed -i \
		-e '/<VirtualHost _default_:443>/,/#<\/VirtualHost>/ s~^~#~' \
		/etc/httpd/conf.d/ssl.conf \
	&& cat \
		/etc/httpd/conf.d/ssl.conf \
		> /etc/httpd/conf.d/ssl.conf.off \
	&& > \
		/etc/httpd/conf.d/ssl.conf \
	&& chmod 444 \
		/etc/httpd/conf.d/ssl.conf

# -----------------------------------------------------------------------------
# Limit threads for the application user
# -----------------------------------------------------------------------------
RUN { \
		echo ''; \
		echo -e '@apache\tsoft\tnproc\t85'; \
		echo -e '@apache\thard\tnproc\t170'; \
	} >> /etc/security/limits.conf

# -----------------------------------------------------------------------------
# Global PHP configuration changes
# -----------------------------------------------------------------------------
RUN sed \
		-e 's~^; .*$~~' \
		-e 's~^;*$~~' \
		-e '/^$/d' \
		-e 's~^\[~\n\[~g' \
		/etc/php.ini \
		> /etc/php.d/00-php.ini.default \
	&& sed \
		-e 's~^;user_ini.filename =$~user_ini.filename =~g' \
		-e 's~^;cgi.fix_pathinfo=1$~cgi.fix_pathinfo=1~g' \
		-e 's~^;date.timezone =$~date.timezone = UTC~g' \
		-e 's~^expose_php = On$~expose_php = Off~g' \
		/etc/php.d/00-php.ini.default \
		> /etc/php.d/00-php.ini

# -----------------------------------------------------------------------------
# APC op-code cache stats
#	Note there will be 1 cache per process if using mod_fcgid
# -----------------------------------------------------------------------------
RUN sed -i \
	-e "s~'ADMIN_PASSWORD','password'~'ADMIN_PASSWORD','apc!123'~g" \
	-e "s~'DATE_FORMAT', 'Y/m/d H:i:s'~'DATE_FORMAT', 'Y-m-d H:i:s'~g" \
	-e "s~php_uname('n');~gethostname();~g" \
	/usr/share/php-pecl-apc/apc.php

# -----------------------------------------------------------------------------
# Add default system users
# -----------------------------------------------------------------------------
RUN useradd -r -M -d /var/www/app -s /sbin/nologin app \
	&& useradd -r -M -d /var/www/app -s /sbin/nologin -G apache,app app-www \
	&& usermod -a -G app-www app \
	&& usermod -a -G app-www,app apache

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD usr/sbin/httpd-bootstrap \
	usr/sbin/httpd-startup \
	usr/sbin/httpd-wrapper \
	/usr/sbin/
ADD opt/scmi \
	/opt/scmi/
ADD etc/profile.d \
	/etc/profile.d/
ADD etc/systemd/system \
	/etc/systemd/system/
ADD etc/services-config/httpd/httpd-bootstrap.conf \
	/etc/services-config/httpd/
ADD etc/services-config/httpd/conf.d/*.conf \
	/etc/services-config/httpd/conf.d/
ADD etc/services-config/supervisor/supervisord.d \
	/etc/services-config/supervisor/supervisord.d/

RUN mkdir -p \
		/etc/services-config/{httpd/{conf,conf.d},ssl/{certs,private}} \
	&& cp \
		/etc/httpd/conf/httpd.conf \
		/etc/services-config/httpd/conf/ \
	&& ln -sf \
		/etc/services-config/httpd/httpd-bootstrap.conf \
		/etc/httpd-bootstrap.conf \
	&& ln -sf \
		/etc/services-config/httpd/conf/httpd.conf \
		/etc/httpd/conf/httpd.conf \
	&& ln -sf \
		/etc/services-config/ssl/certs/localhost.crt \
		/etc/pki/tls/certs/localhost.crt \
	&& ln -sf \
		/etc/services-config/ssl/private/localhost.key \
		/etc/pki/tls/private/localhost.key \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.conf \
		/etc/supervisord.conf \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/httpd-bootstrap.conf \
		/etc/supervisord.d/httpd-bootstrap.conf \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/httpd-wrapper.conf \
		/etc/supervisord.d/httpd-wrapper.conf \
	&& chmod 700 \
		/usr/sbin/httpd-{bootstrap,startup,wrapper}

# -----------------------------------------------------------------------------
# Package installation
# -----------------------------------------------------------------------------
RUN mkdir -p -m 750 ${PACKAGE_PATH} \
	&& curl -Lso /tmp/${PACKAGE_NAME}.tar.gz \
		https://github.com/jdeathe/php-hello-world/archive/${PACKAGE_RELEASE_VERSION}.tar.gz \
	&& tar -xzpf /tmp/${PACKAGE_NAME}.tar.gz \
		--strip-components=1 \
		--exclude="*.gitkeep" \
		-C ${PACKAGE_PATH} \
	&& rm -f /tmp/${PACKAGE_NAME}.tar.gz \
	&& sed -i \
		-e 's~^description =.*$~description = "This CentOS / Apache / PHP (Standard) service is running in a container."~' \
		${PACKAGE_PATH}/etc/views/index.ini \
	&& $(\
		if [[ -f /usr/share/php-pecl-apc/apc.php ]]; then \
			cp \
				/usr/share/php-pecl-apc/apc.php \
				${PACKAGE_PATH}/public_html/_apc.php; \
		fi \
	) \
	&& chown -R app:app-www ${PACKAGE_PATH} \
	&& find ${PACKAGE_PATH} -type d -exec chmod 750 {} + \
	&& find ${PACKAGE_PATH}/var -type d -exec chmod 770 {} + \
	&& find ${PACKAGE_PATH} -type f -exec chmod 640 {} + \
	&& find ${PACKAGE_PATH}/bin -type f -exec chmod 750 {} +

EXPOSE 80 8443 443

# -----------------------------------------------------------------------------
# Set default environment variables used to configure the service container
# -----------------------------------------------------------------------------
ENV APACHE_CONTENT_ROOT="/var/www/${PACKAGE_NAME}" \
	BASH_ENV="/usr/sbin/httpd-startup" \
	ENV="/usr/sbin/httpd-startup"
ENV APACHE_CUSTOM_LOG_FORMAT="combined" \
	APACHE_CUSTOM_LOG_LOCATION="var/log/apache_access_log" \
	APACHE_ERROR_LOG_LOCATION="var/log/apache_error_log" \
	APACHE_ERROR_LOG_LEVEL="warn" \
	APACHE_EXTENDED_STATUS_ENABLED="false" \
	APACHE_HEADER_X_SERVICE_UID="{{HOSTNAME}}" \
	APACHE_LOAD_MODULES="authz_user_module log_config_module expires_module deflate_module headers_module setenvif_module mime_module status_module dir_module alias_module version_module" \
	APACHE_MOD_SSL_ENABLED="false" \
	APACHE_MPM="prefork" \
	APACHE_OPERATING_MODE="production" \
	APACHE_PUBLIC_DIRECTORY="public_html" \
	APACHE_RUN_GROUP="app-www" \
	APACHE_RUN_USER="app-www" \
	APACHE_SERVER_ALIAS="" \
	APACHE_SERVER_NAME="" \
	APACHE_SSL_CERTIFICATE="" \
	APACHE_SSL_CIPHER_SUITE="ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS" \
	APACHE_SSL_PROTOCOL="All -SSLv2 -SSLv3" \
	APACHE_SYSTEM_USER="app" \
	PACKAGE_PATH="${PACKAGE_PATH}" \
	PHP_OPTIONS_DATE_TIMEZONE="UTC" \
	SSH_AUTOSTART_SSHD=false \
	SSH_AUTOSTART_SSHD_BOOTSTRAP=false

# -----------------------------------------------------------------------------
# Set image metadata
# -----------------------------------------------------------------------------
ARG RELEASE_VERSION="1.9.0"
LABEL \
	install="docker run \
--rm \
--privileged \
--volume /:/media/root \
--env BASH_ENV="" \
--env ENV="" \
jdeathe/centos-ssh-apache-php:${RELEASE_VERSION} \
/usr/sbin/scmi install \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION}" \
	uninstall="docker run \
--rm \
--privileged \
--volume /:/media/root \
--env BASH_ENV="" \
--env ENV="" \
jdeathe/centos-ssh-apache-php:${RELEASE_VERSION} \
/usr/sbin/scmi uninstall \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION}" \
	org.deathe.name="centos-ssh-apache-php" \
	org.deathe.version="${RELEASE_VERSION}" \
	org.deathe.release="jdeathe/centos-ssh-apache-php:${RELEASE_VERSION}" \
	org.deathe.license="MIT" \
	org.deathe.vendor="jdeathe" \
	org.deathe.url="https://github.com/jdeathe/centos-ssh-apache-php" \
	org.deathe.description="CentOS-6 6.8 x86_64 - Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1."

CMD ["/usr/sbin/httpd-startup", "/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]