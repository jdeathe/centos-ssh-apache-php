# =============================================================================
# jdeathe/centos-ssh-apache-php
#
# CentOS-6, Apache 2.4, PHP 5.6, PHP memcached 2.2, Zend Opcache 7.0
#
# =============================================================================
FROM jdeathe/centos-ssh:centos-6-1.7.3

MAINTAINER James Deathe <james.deathe@gmail.com>

# Use the form ([{fqdn}-]{package-name}|[{fqdn}-]{provider-name})
ARG PACKAGE_NAME="php-hello-world"
ARG PACKAGE_PATH="/opt/${PACKAGE_NAME}"
ARG PACKAGE_RELEASE_VERSION="0.3.0"

# -----------------------------------------------------------------------------
# IUS Apache 2.4, PHP 5.6
# -----------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& yum --setopt=tsflags=nodocs -y install \
		elinks-0.12-0.21.pre5.el6_3 \
		httpd24u-httpd \
		httpd24u-httpd-tools \
		httpd24u-mod_ssl \
		php56u-fpm \
		php56u-fpm-httpd \
		php56u-php-cli \
		php56u-opcache \
		php56u-pecl-memcached \
	&& yum versionlock add \
		elinks \
		httpd24u* \
		php56u* \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# Global Apache configuration changes
# -----------------------------------------------------------------------------
RUN cp -pf \
		/etc/httpd/conf/httpd.conf \
		/etc/httpd/conf/httpd.conf.default \
	&& sed -i \
		-e 's~^KeepAlive .*$~KeepAlive On~g' \
		-e 's~^MaxKeepAliveRequests .*$~MaxKeepAliveRequests 200~g' \
		-e 's~^KeepAliveTimeout .*$~KeepAliveTimeout 2~g' \
		-e 's~^ServerSignature On$~ServerSignature Off~g' \
		-e 's~^ServerTokens OS$~ServerTokens Prod~g' \
		-e 's~^NameVirtualHost \(.*\)$~#NameVirtualHost \1~g' \
		-e 's~^User .*$~User ${APACHE_RUN_USER}~g' \
		-e 's~^Group .*$~Group ${APACHE_RUN_GROUP}~g' \
		-e 's~^DocumentRoot \(.*\)$~#DocumentRoot \1~g' \
		/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable Apache directory indexes
# -----------------------------------------------------------------------------
RUN sed -i \
		-e 's~^IndexOptions \(.*\)$~#IndexOptions \1~g' \
		-e 's~^IndexIgnore \(.*\)$~#IndexIgnore \1~g' \
		-e 's~^AddIconByEncoding \(.*\)$~#AddIconByEncoding \1~g' \
		-e 's~^AddIconByType \(.*\)$~#AddIconByType \1~g' \
		-e 's~^AddIcon \(.*\)$~#AddIcon \1~g' \
		-e 's~^DefaultIcon \(.*\)$~#DefaultIcon \1~g' \
		-e 's~^ReadmeName \(.*\)$~#ReadmeName \1~g' \
		-e 's~^HeaderName \(.*\)$~#HeaderName \1~g' \
		-e 's~^\(Alias /icons/ ".*"\)$~#\1~' \
		-e '/<Directory "\/var\/www\/icons">/,/#<\/Directory>/ s~^~#~' \
		/etc/httpd/conf/httpd.conf \
	&& mv \
		/etc/httpd/conf.d/autoindex.conf \
		/etc/httpd/conf.d/autoindex.conf.off \
	&& touch \
		/etc/httpd/conf.d/autoindex.conf \
	&& chmod 444 \
		/etc/httpd/conf.d/autoindex.conf

# -----------------------------------------------------------------------------
# Disable Apache language based content negotiation
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^LanguagePriority \(.*\)$~#LanguagePriority \1~g' \
	-e 's~^ForceLanguagePriority \(.*\)$~#ForceLanguagePriority \1~g' \
	-e 's~^AddLanguage \(.*\)$~#AddLanguage \1~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable all Apache modules and enable the minimum
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^\(LoadModule .*\)$~#\1~g' \
	-e 's~^#LoadModule mime_module ~LoadModule mime_module ~g' \
	-e 's~^#LoadModule log_config_module ~LoadModule log_config_module ~g' \
	-e 's~^#LoadModule setenvif_module ~LoadModule setenvif_module ~g' \
	-e 's~^#LoadModule status_module ~LoadModule status_module ~g' \
	-e 's~^#LoadModule authz_host_module ~LoadModule authz_host_module ~g' \
	-e 's~^#LoadModule dir_module ~LoadModule dir_module ~g' \
	-e 's~^#LoadModule alias_module ~LoadModule alias_module ~g' \
	-e 's~^#LoadModule expires_module ~LoadModule expires_module ~g' \
	-e 's~^#LoadModule deflate_module ~LoadModule deflate_module ~g' \
	-e 's~^#LoadModule headers_module ~LoadModule headers_module ~g' \
	-e 's~^#LoadModule alias_module ~LoadModule alias_module ~g' \
	-e 's~^#LoadModule version_module ~LoadModule version_module ~g' \
	/etc/httpd/conf.modules.d/00-base.conf \
	/etc/httpd/conf.modules.d/00-dav.conf \
	/etc/httpd/conf.modules.d/00-lua.conf \
	/etc/httpd/conf.modules.d/00-proxy.conf

# -----------------------------------------------------------------------------
# Disable the default SSL Virtual Host
# -----------------------------------------------------------------------------
RUN sed -i \
	-e '/<VirtualHost _default_:443>/,/#<\/VirtualHost>/ s~^~#~' \
	/etc/httpd/conf.d/ssl.conf

# -----------------------------------------------------------------------------
# Custom Apache configuration
# -----------------------------------------------------------------------------
RUN { \
		echo ''; \
		echo '#'; \
		echo '# Custom configuration'; \
		echo '#'; \
		echo 'Include /etc/services-config/httpd/conf.d/*.conf'; \
		echo 'LogFormat \'; \
		echo '  "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" \'; \
		echo '  forwarded_for_combined'; \
		echo 'Options -Indexes'; \
		echo 'TraceEnable Off'; \
		echo 'UseCanonicalPhysicalPort On'; \
	} >> /etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable the SSL support by default
# -----------------------------------------------------------------------------
RUN mv \
		/etc/httpd/conf.d/ssl.conf \
		/etc/httpd/conf.d/ssl.conf.off \
	&& touch \
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
RUN cp -pf \
		/etc/php-fpm.conf \
		/etc/php-fpm.conf.default \
	&& cp -pf \
		/etc/php-fpm.d/www.conf \
		/etc/php-fpm.d/www.conf.default \
	&& cp -pf \
		/etc/httpd/conf.d/php-fpm.conf \
		/etc/httpd/conf.d/php-fpm.conf.default \
	&& sed \
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
		> /etc/php.d/00-php.ini \
	&& sed -i \
		-e 's~^\[www\]$~[{{APACHE_RUN_USER}}]~' \
		-e 's~^user = php-fpm$~user = {{APACHE_RUN_USER}}~' \
		-e 's~^group = php-fpm$~group = {{APACHE_RUN_GROUP}}~' \
		-e 's~^listen = 127.0.0.1:9000$~;listen = 127.0.0.1:9000~' \
		-e 's~^;listen = /var/run/php-fpm/www.sock$~listen = /var/run/php-fpm/{{APACHE_RUN_USER}}.sock~' \
		-e 's~^;listen.owner = root$~listen.owner = {{APACHE_RUN_USER}}~' \
		-e 's~^;listen.group = root$~listen.group = {{APACHE_RUN_GROUP}}~' \
		-e 's~^\(php_admin_value\[error_log\].*\)$~;\1~' \
		-e 's~^\(php_admin_flag\[log_errors\].*\)$~;\1~' \
		-e 's~^\(php_value\[session.save_handler\].*\)$~;\1~' \
		-e 's~^\(php_value\[session.save_path\].*\)$~;\1~' \
		-e 's~^\(php_value\[soap.wsdl_cache_dir\].*\)$~;\1~' \
		/etc/php-fpm.d/www.conf \
	&& mv \
		/etc/php-fpm.d/www.conf \
		/etc/php-fpm.d/www.conf.template \
	&& sed -i \
		-e 's~^\([ \t]*\)\(SetHandler "proxy:fcgi:.*\)$~\1#\2~' \
		-e 's~^\([ \t]*\)#\(SetHandler "proxy:unix:.*\)$~\1\2~' \
		/etc/httpd/conf.d/php-fpm.conf

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
	usr/sbin/php-fpm-wrapper \
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
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/php-fpm-wrapper.conf \
		/etc/supervisord.d/php-fpm-wrapper.conf \
	&& chmod 700 \
		/usr/sbin/{httpd-{bootstrap,startup,wrapper},php-fpm-wrapper}

# -----------------------------------------------------------------------------
# Create and populate the install directory
# -----------------------------------------------------------------------------
RUN mkdir -p -m 750 ${PACKAGE_PATH}
RUN curl -Lso /tmp/${PACKAGE_NAME}.tar.gz \
		https://github.com/jdeathe/php-hello-world/archive/${PACKAGE_RELEASE_VERSION}.tar.gz \
	&& tar -xzpf /tmp/${PACKAGE_NAME}.tar.gz \
		--strip-components=1 \
		--exclude="*.gitkeep" \
		-C ${PACKAGE_PATH} \
	&& rm -f /tmp/app.tar.gz \
	&& sed -i \
		-e 's~^description =.*$~description = "This CentOS / Apache / PHP (php-fpm) service is running in a container."~' \
		${PACKAGE_PATH}/etc/views/index.ini \
	&& $(\
		if [[ -f /usr/share/php-pecl-apc/apc.php ]]; then \
			cp \
				/usr/share/php-pecl-apc/apc.php \
				${PACKAGE_PATH}/public_html/_apc.php; \
		fi \
	)

# -----------------------------------------------------------------------------
# Set install directory/file permissions
# -----------------------------------------------------------------------------
RUN chown -R app:app-www ${PACKAGE_PATH} \
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
	APACHE_LOAD_MODULES="authz_core_module authz_user_module log_config_module expires_module deflate_module filter_module headers_module setenvif_module socache_shmcb_module mime_module status_module dir_module alias_module unixd_module version_module proxy_module proxy_fcgi_module" \
	APACHE_MOD_SSL_ENABLED="false" \
	APACHE_MPM="prefork" \
	APACHE_OPERATING_MODE="production" \
	APACHE_PUBLIC_DIRECTORY="public_html" \
	APACHE_RUN_GROUP="app-www" \
	APACHE_RUN_USER="app-www" \
	APACHE_SERVER_ALIAS="" \
	APACHE_SERVER_NAME="app-1.local" \
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
ARG RELEASE_VERSION="1.7.3"
LABEL \
	install="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh-apache-php:centos-6-${RELEASE_VERSION} \
/usr/sbin/scmi install \
--chroot=/media/root \
--name=\${NAME} \
--tag=centos-6-${RELEASE_VERSION}" \
	uninstall="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh-apache-php:centos-6-${RELEASE_VERSION} \
/usr/sbin/scmi uninstall \
--chroot=/media/root \
--name=\${NAME} \
--tag=centos-6-${RELEASE_VERSION}" \
	org.deathe.name="centos-ssh-apache-php" \
	org.deathe.version="${RELEASE_VERSION}" \
	org.deathe.release="jdeathe/centos-ssh-apache-php:centos-6-${RELEASE_VERSION}" \
	org.deathe.license="MIT" \
	org.deathe.vendor="jdeathe" \
	org.deathe.url="https://github.com/jdeathe/centos-ssh-apache-php" \
	org.deathe.description="CentOS-6 6.8 x86_64 - IUS Apache 2.4, IUS PHP 5.6, PHP memcached 2.2, Zend Opcache 7.0."

CMD ["/usr/sbin/httpd-startup", "/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]