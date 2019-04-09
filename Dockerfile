FROM jdeathe/centos-ssh:1.10.1

# Use the form ([{fqdn}-]{package-name}|[{fqdn}-]{provider-name})
ARG PACKAGE_NAME="app"
ARG PACKAGE_PATH="/opt/${PACKAGE_NAME}"
ARG PACKAGE_RELEASE_VERSION="0.11.0"
ARG RELEASE_VERSION="1.11.1"

# ------------------------------------------------------------------------------
# - Base install of required packages
# ------------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& yum -y install \
		--setopt=tsflags=nodocs \
		--disableplugin=fastestmirror \
		elinks-0.12-0.21.pre5.el6_3 \
		httpd-2.2.15-69.el6.centos \
		mod_ssl-2.2.15-69.el6.centos \
		php-5.3.3-49.el6 \
		php-cli-5.3.3-49.el6 \
		php-common-5.3.3-49.el6 \
		php-zts-5.3.3-49.el6 \
		php-pecl-apc-3.1.9-2.el6 \
		php-pecl-memcached-1.0.0-1.el6 \
		php-pecl-redis-2.2.8-1.el6 \
	&& yum versionlock add \
		elinks \
		httpd \
		mod_ssl \
		php* \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# ------------------------------------------------------------------------------
# Copy files into place
# ------------------------------------------------------------------------------
ADD src /

# ------------------------------------------------------------------------------
# Provisioning
# - Add default system users
# - Limit threads for the application user
# - Disable Apache directory indexes and welcome page
# - Disable Apache language based content negotiation
# - Custom Apache configuration
# - Disable all Apache modules and enable the minimum
# - Disable SSL
# - Disable the default SSL Virtual Host
# - Global PHP configuration changes
# - APC configuration
# - Replace placeholders with values in systemd service unit template
# - Set permissions
# ------------------------------------------------------------------------------
RUN useradd -r -M -d /var/www/app -s /sbin/nologin app \
	&& useradd -r -M -d /var/www/app -s /sbin/nologin -G apache,app app-www \
	&& usermod -a -G app-www app \
	&& usermod -a -G app-www,app apache \
	&& usermod -L app \
	&& usermod -L app-www \
	&& { printf -- \
		'\n@apache\tsoft\tnproc\t%s\n@apache\thard\tnproc\t%s\n' \
		'85' \
		'170'; \
	} >> /etc/security/limits.conf \
	&& cp -pf \
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
	&& { printf -- \
			'\n%s\n%s\n%s\n%s\\\n%s%s\\\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
			'#' \
			'# Custom configuration' \
			'#' \
			'LogFormat ' \
			'  "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b' \
			' \"%{Referer}i\" \"%{User-Agent}i\"" ' \
			'  forwarded_for_combined' \
			'Listen 8443' \
			'Options -Indexes' \
			'ServerSignature Off' \
			'ServerTokens Prod' \
			'TraceEnable Off' \
			'UseCanonicalName On' \
			'UseCanonicalPhysicalPort On'; \
		} >> /etc/httpd/conf/httpd.conf \
	&& sed -i \
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
		/etc/httpd/conf/httpd.conf \
	&& sed -i \
		-e '/<VirtualHost _default_:443>/,/<\/VirtualHost>/ s~^~#~' \
		/etc/httpd/conf.d/ssl.conf \
	&& cat \
		/etc/httpd/conf.d/ssl.conf \
		> /etc/httpd/conf.d/ssl.conf.off \
	&& truncate -s 0 \
		/etc/httpd/conf.d/ssl.conf \
	&& chmod 644 \
		/etc/httpd/conf.d/ssl.conf \
	&& sed \
		-e 's~^; .*$~~' \
		-e 's~^;*$~~' \
		-e '/^$/d' \
		-e 's~^\[~\n\[~g' \
		/etc/php.ini \
		> /etc/php.d/00-php.ini.default \
	&& sed \
		-e 's~^; .*$~~' \
		-e 's~^;*$~~' \
		-e '/^$/d' \
		-e 's~^\[~\n\[~g' \
		/etc/php.d/apc.ini \
		> /etc/php.d/apc.ini.default \
	&& sed -r \
		-e 's~^;(user_ini.filename =)$~\1~g' \
		-e 's~^;(cgi.fix_pathinfo=1)$~\1~g' \
		-e 's~^;(date.timezone =)$~\1 UTC~g' \
		-e 's~^(expose_php = )On$~\1Off~g' \
		-e 's~^;(realpath_cache_size = ).*$~\14096k~' \
		-e 's~^;(realpath_cache_ttl = ).*$~\1600~' \
		-e 's~^;?(session.name = ).*$~\1"${PHP_OPTIONS_SESSION_NAME:-PHPSESSID}"~' \
		-e 's~^;?(session.save_handler = ).*$~\1"${PHP_OPTIONS_SESSION_SAVE_HANDLER:-files}"~' \
		-e 's~^;?(session.save_path = ).*$~\1"${PHP_OPTIONS_SESSION_SAVE_PATH:-/var/lib/php/session}"~' \
		/etc/php.d/00-php.ini.default \
		> /etc/php.d/00-php.ini \
	&& sed \
		-e 's~^\(apc.stat=\).*$~\10~g' \
		-e 's~^\(apc.shm_size=\).*$~\1128M~g' \
		-e 's~^\(apc.enable_cli=\).*$~\11~g' \
		-e 's~^\(apc.file_update_protection=\).*$~\10~g' \
		/etc/php.d/apc.ini.default \
		> /etc/php.d/apc.ini \
	&& sed -i \
		-e "s~'ADMIN_PASSWORD','password'~'ADMIN_PASSWORD','apc!123'~g" \
		-e "s~'DATE_FORMAT', 'Y/m/d H:i:s'~'DATE_FORMAT', 'Y-m-d H:i:s'~g" \
		-e "s~php_uname(\'n\');~gethostname();~g" \
		/usr/share/php-pecl-apc/apc.php \
	&& sed -i \
		-e "s~{{RELEASE_VERSION}}~${RELEASE_VERSION}~g" \
		/etc/systemd/system/centos-ssh-apache-php@.service \
	&& chmod 700 \
		/usr/{bin/healthcheck,sbin/httpd-{bootstrap,wrapper}}

# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
RUN mkdir -p -m 750 ${PACKAGE_PATH} \
	&& curl -Ls \
		https://github.com/jdeathe/php-hello-world/archive/${PACKAGE_RELEASE_VERSION}.tar.gz \
	| tar -xzpf - \
		--strip-components=1 \
		--exclude="*.gitkeep" \
		-C ${PACKAGE_PATH} \
	&& sed -i \
		-e 's~^description =.*$~description = "This CentOS / Apache / PHP (Standard) service is running in a container."~' \
		${PACKAGE_PATH}/etc/views/index.ini \
	&& mv \
		${PACKAGE_PATH}/public \
		${PACKAGE_PATH}/public_html \
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

EXPOSE 80 443 8443

# ------------------------------------------------------------------------------
# Set default environment variables used to configure the service container
# ------------------------------------------------------------------------------
ENV APACHE_AUTOSTART_HTTPD_BOOTSTRAP="true" \
	APACHE_AUTOSTART_HTTPD_WRAPPER="true" \
	APACHE_CONTENT_ROOT="/var/www/${PACKAGE_NAME}" \
	APACHE_CUSTOM_LOG_FORMAT="combined" \
	APACHE_CUSTOM_LOG_LOCATION="var/log/apache_access_log" \
	APACHE_ERROR_LOG_LOCATION="var/log/apache_error_log" \
	APACHE_ERROR_LOG_LEVEL="warn" \
	APACHE_EXTENDED_STATUS_ENABLED="false" \
	APACHE_HEADER_X_SERVICE_UID="{{HOSTNAME}}" \
	APACHE_LOAD_MODULES="" \
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
	PHP_OPTIONS_SESSION_NAME="PHPSESSID" \
	PHP_OPTIONS_SESSION_SAVE_HANDLER="files" \
	PHP_OPTIONS_SESSION_SAVE_PATH="var/session" \
	SSH_AUTOSTART_SSHD="false" \
	SSH_AUTOSTART_SSHD_BOOTSTRAP="false" \
	SSH_AUTOSTART_SUPERVISOR_STDOUT="false"

# ------------------------------------------------------------------------------
# Set image metadata
# ------------------------------------------------------------------------------
LABEL \
	maintainer="James Deathe <james.deathe@gmail.com>" \
	install="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh-apache-php:${RELEASE_VERSION} \
/usr/sbin/scmi install \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION}" \
	uninstall="docker run \
--rm \
--privileged \
--volume /:/media/root \
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
	org.deathe.description="CentOS-6 6.10 x86_64 - Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1."

HEALTHCHECK \
	--interval=1s \
	--timeout=1s \
	--retries=10 \
	CMD ["/usr/bin/healthcheck"]

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]
