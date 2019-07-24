FROM jdeathe/centos-ssh:2.6.0

# Use the form ([{fqdn}-]{package-name}|[{fqdn}-]{provider-name})
ARG PACKAGE_NAME="app"
ARG PACKAGE_PATH="/opt/${PACKAGE_NAME}"
ARG PACKAGE_RELEASE_VERSION="0.12.0"
ARG RELEASE_VERSION="3.3.0"

# ------------------------------------------------------------------------------
# Base install of required packages
# ------------------------------------------------------------------------------
RUN yum -y install \
		--setopt=tsflags=nodocs \
		--disableplugin=fastestmirror \
		elinks-0.12-0.37.pre6.el7.0.1 \
		httpd24u-2.4.39-2.el7.ius \
		httpd24u-tools \
		httpd24u-mod_ssl \
		php72u-cli \
		php72u-common-7.2.19-1.el7.ius \
		php72u-fpm \
		php72u-fpm-httpd \
		php72u-opcache \
		php72u-pecl-memcached-3.0.4-2.ius.el7 \
		php72u-pecl-redis-3.1.6-2.ius.el7 \
	&& yum versionlock add \
		elinks \
		httpd24u* \
		php72u* \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all \
	&& /bin/find /usr/share \
		-type f \
		-regextype posix-extended \
		-regex '.*\.(jpg|png)$' \
		-delete

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
		-e '/^KeepAlive .*$/d' \
		-e '/^MaxKeepAliveRequests .*$/d' \
		-e '/^KeepAliveTimeout .*$/d' \
		-e '/^ServerSignature On$/d' \
		-e '/^ServerTokens OS$/d' \
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
		-e 's~^\(Alias /icons/ ".*"\)$~#\1~' \
		-e '/<Directory "\/var\/www\/icons">/,/#<\/Directory>/ s~^~#~' \
		-e 's~^LanguagePriority \(.*\)$~#LanguagePriority \1~g' \
		-e 's~^ForceLanguagePriority \(.*\)$~#ForceLanguagePriority \1~g' \
		-e 's~^AddLanguage \(.*\)$~#AddLanguage \1~g' \
		/etc/httpd/conf/httpd.conf \
	&& truncate -s 0 \
		/etc/httpd/conf.d/autoindex.conf \
	&& chmod 444 \
		/etc/httpd/conf.d/autoindex.conf \
	&& truncate -s 0 \
		/etc/httpd/conf.d/welcome.conf \
	&& chmod 444 \
		/etc/httpd/conf.d/welcome.conf \
	&& { printf -- \
		'\n%s\n%s\n%s\n%s\n%s\n%s\n%s\\\n%s%s\\\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
		'#' \
		'# Custom configuration' \
		'#' \
		'KeepAlive On' \
		'MaxKeepAliveRequests 200' \
		'KeepAliveTimeout 2' \
		'LogFormat ' \
		'  "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b' \
		' \"%{Referer}i\" \"%{User-Agent}i\"" ' \
		'  forwarded_for_combined' \
		'ExtendedStatus Off' \
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
		-e 's~^#\(LoadModule version_module .*\)$~\1~' \
		/etc/httpd/conf.modules.d/00-base.conf \
		/etc/httpd/conf.modules.d/00-dav.conf \
		/etc/httpd/conf.modules.d/00-lua.conf \
		/etc/httpd/conf.modules.d/00-proxy.conf \
		/etc/httpd/conf.modules.d/00-ssl.conf \
		/etc/httpd/conf.modules.d/00-systemd.conf \
	&& sed -ri \
		-e '/<VirtualHost _default_:443>/,/<\/VirtualHost>/ s~^~#~' \
		-e 's~(SSLSessionCacheTimeout.*)$~\1\n\nSSLUseStapling on\nSSLStaplingCache shmcb:/run/httpd/sslstaplingcache(512000)\nSSLStaplingResponderTimeout 5\nSSLStaplingReturnResponderErrors off~' \
		/etc/httpd/conf.d/ssl.conf \
	&& cat \
		/etc/httpd/conf.d/ssl.conf \
		> /etc/httpd/conf.d/ssl.conf.off \
	&& truncate -s 0 \
		/etc/httpd/conf.d/ssl.conf \
	&& chmod 644 \
		/etc/httpd/conf.d/ssl.conf \
	&& cp -pf \
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
	&& sed -r \
		-e 's~^;?(cgi.fix_pathinfo( )?=).*$~\1\21~g' \
		-e 's~^;?(date.timezone( )?=).*$~\1\2"${PHP_OPTIONS_DATE_TIMEZONE:-UTC}"~g' \
		-e 's~^;?(expose_php( )?=).*$~\1\2Off~g' \
		-e 's~^;?(realpath_cache_size( )?=).*$~\1\24096k~' \
		-e 's~^;?(realpath_cache_ttl( )?=).*$~\1\2600~' \
		-e 's~^;?(session.cookie_httponly( )?=).*$~\1\21~' \
		-e 's~^;?(session.name( )?=).*$~\1\2"${PHP_OPTIONS_SESSION_NAME:-PHPSESSID}"~' \
		-e 's~^;?(session.save_handler( )?=).*$~\1\2"${PHP_OPTIONS_SESSION_SAVE_HANDLER:-files}"~' \
		-e 's~^;?(session.save_path( )?=).*$~\1\2"${PHP_OPTIONS_SESSION_SAVE_PATH:-/var/lib/php/session}"~' \
		-e 's~^;?(session.sid_bits_per_character( )?=).*$~\1\25~' \
		-e 's~^;?(session.sid_length( )?=).*$~\1\264~' \
		-e 's~^;?(session.use_strict_mode( )?=).*$~\1\21~' \
		-e 's~^;?(user_ini.filename( )?=).*$~\1~g' \
		/etc/php.d/00-php.ini.default \
		> /etc/php.d/00-php.ini \
	&& sed \
		-e 's~^; .*$~~' \
		-e 's~^;*$~~' \
		-e '/^$/d' \
		-e 's~^\[~\n\[~g' \
		/etc/php.d/10-opcache.ini \
		> /etc/php.d/10-opcache.ini.default \
	&& sed \
		-e 's~^;\(opcache.enable_cli=\).*$~\11~g' \
		-e 's~^\(opcache.max_accelerated_files=\).*$~\132531~g' \
		-e 's~^;\(opcache.validate_timestamps=\).*$~\10~g' \
		/etc/php.d/10-opcache.ini.default \
		> /etc/php.d/10-opcache.ini \
	&& sed -r -i \
		-e 's~^(error_log( )?=).*$~\1\2/dev/stderr~' \
		-e 's~^;?(systemd_interval( )?=).*$~\1\20~' \
		/etc/php-fpm.conf \
	&& sed -i \
		-e 's~^\[www\]$~[{{APACHE_RUN_USER}}]~' \
		-e 's~^user = php-fpm$~user = {{APACHE_RUN_USER}}~' \
		-e 's~^group = php-fpm$~group = {{APACHE_RUN_GROUP}}~' \
		-e 's~^listen = 127.0.0.1:9000$~;listen = 127.0.0.1:9000~' \
		-e 's~^;listen = /run/php-fpm/www.sock$~listen = /run/php-fpm/{{APACHE_RUN_USER}}.sock~' \
		-e 's~^;listen.owner = root$~listen.owner = {{APACHE_RUN_USER}}~' \
		-e 's~^;listen.group = root$~listen.group = {{APACHE_RUN_GROUP}}~' \
		-e 's~^pm.max_children = 50$~pm.max_children = 64~' \
		-e 's~^slowlog = /var/log/php-fpm/www-slow.log$~slowlog = /var/log/php-fpm/{{APACHE_RUN_USER}}-slow.log~' \
		-e 's~^\(php_admin_value\[error_log\].*\)$~;\1~' \
		-e 's~^\(php_admin_flag\[log_errors\].*\)$~;\1~' \
		-e 's~^\(php_value\[session.save_handler\].*\)$~;\1~' \
		-e 's~^\(php_value\[session.save_path\].*\)$~;\1~' \
		-e 's~^\(php_value\[soap.wsdl_cache_dir\].*\)$~;\1~' \
		-e 's~^;\(pm.status_path = \).*$~\1/status~' \
		/etc/php-fpm.d/www.conf \
	&& cat \
		/etc/php-fpm.d/www.conf \
		> /etc/php-fpm.d/www.conf.template \
	&& sed -i \
		-e 's~^\([ \t]*\)\(SetHandler "proxy:fcgi:.*\)$~\1#\2~' \
		-e 's~^\([ \t]*\)#\(SetHandler "proxy:unix:.*\)$~\1\2~' \
		/etc/httpd/conf.d/php-fpm.conf \
	&& sed -i \
		-e "s~{{RELEASE_VERSION}}~${RELEASE_VERSION}~g" \
		/etc/systemd/system/centos-ssh-apache-php@.service \
	&& chmod 644 \
		/etc/supervisord.d/{20-httpd-bootstrap,50-php-fpm-wrapper,70-httpd-wrapper}.conf \
	&& chmod 700 \
		/usr/{bin/healthcheck,sbin/{httpd-{bootstrap,wrapper},php-fpm-wrapper}}

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
		-e 's~^description =.*$~description = "This CentOS / Apache / PHP-FPM (FastCGI) service is running in a container."~' \
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
ENV \
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
	ENABLE_HTTPD_BOOTSTRAP="true" \
	ENABLE_HTTPD_WRAPPER="true" \
	ENABLE_PHP_FPM_WRAPPER="true" \
	ENABLE_SSHD_BOOTSTRAP="false" \
	ENABLE_SSHD_WRAPPER="false" \
	PACKAGE_PATH="${PACKAGE_PATH}" \
	PHP_OPTIONS_DATE_TIMEZONE="UTC" \
	PHP_OPTIONS_SESSION_NAME="PHPSESSID" \
	PHP_OPTIONS_SESSION_SAVE_HANDLER="files" \
	PHP_OPTIONS_SESSION_SAVE_PATH="var/session"

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
	org.deathe.description="IUS Apache 2.4, IUS PHP-FPM 7.2, PHP memcached 3.0, PHP redis 3.1, Zend Opcache 7.2 - CentOS-7 7.6.1810 x86_64."

HEALTHCHECK \
	--interval=1s \
	--timeout=1s \
	--retries=10 \
	CMD ["/usr/bin/healthcheck"]

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]
