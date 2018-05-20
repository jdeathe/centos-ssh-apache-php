readonly DOCKER_HOSTNAME="localhost"
readonly STARTUP_TIME=2
readonly TEST_DIRECTORY="test"

# These should ideally be a static value but hosts might be using this port so 
# need to allow for alternatives.
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-NULL}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-8080}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-9443}"
DOCKER_PORT_MAP_TCP_8443="${DOCKER_PORT_MAP_TCP_8443:-NULL}"

function __destroy ()
{
	local -r session_store_name="memcached.pool-1.1.1"
	local -r session_store_network="bridge_internal_1"

	# Destroy the session store container
	__terminate_container \
		${session_store_name} \
	&> /dev/null

	if [[ -n $(docker network ls -q -f name="${session_store_network}") ]]; then
		docker network rm \
			${session_store_network} \
		&> /dev/null
	fi

	# Truncate cookie-jar
	:> ~/.curl_cookies
}

function __get_container_port ()
{
	local container="${1:-}"
	local port="${2:-}"
	local value=""

	value="$(
		docker port \
			${container} \
			${port}
	)"
	value=${value##*:}

	printf -- \
		'%s' \
		"${value}"
}

# container - Docker container name.
# counter - Timeout counter in seconds.
# process_pattern - Regular expression pattern used to match running process.
# ready_test - Command used to test if the service is ready.
function __is_container_ready ()
{
	local container="${1:-}"
	local counter=$(
		awk \
			-v seconds="${2:-10}" \
			'BEGIN { print 10 * seconds; }'
	)
	local process_pattern="${3:-}"
	local ready_test="${4:-true}"

	until (( counter == 0 )); do
		sleep 0.1

		if docker exec ${container} \
			bash -c "ps axo command \
				| grep -qE \"${process_pattern}\" \
				&& eval \"${ready_test}\"" \
			&> /dev/null
		then
			break
		fi

		(( counter -= 1 ))
	done

	if (( counter == 0 )); then
		return 1
	fi

	return 0
}

function __setup ()
{
	local -r session_store_alias="memcached_1"
	local -r session_store_name="memcached.pool-1.1.1"
	local -r session_store_network="bridge_internal_1"
	local -r session_store_release="1.1.3"

	if [[ -z $(docker network ls -q -f name="${session_store_network}") ]]; then
		docker network create \
			--internal \
			--driver bridge \
			${session_store_network} \
		&> /dev/null
	fi

	# Create the session store container
	__terminate_container \
		${session_store_name} \
	&> /dev/null
	docker run \
		--detach \
		--name ${session_store_name} \
		--network ${session_store_network} \
		--network-alias ${session_store_alias} \
		jdeathe/centos-ssh-memcached:${session_store_release} \
	&> /dev/null

	# Generate a self-signed certificate
	openssl req \
		-x509 \
		-sha256 \
		-nodes \
		-newkey rsa:2048 \
		-days 365 \
		-subj "/CN=www.app-1.local" \
		-keyout /tmp/www.app-1.local.pem \
		-out /tmp/www.app-1.local.pem \
	&> /dev/null

	# Truncate cookie-jar
	:> ~/.curl_cookies
}

# Custom shpec matcher
# Match a string with an Extended Regular Expression pattern.
function __shpec_matcher_egrep ()
{
	local pattern="${2:-}"
	local string="${1:-}"

	printf -- \
		'%s' \
		"${string}" \
	| grep -qE -- \
		"${pattern}" \
		-

	assert equal \
		"${?}" \
		0
}

function __terminate_container ()
{
	local CONTAINER="${1}"

	if docker ps -aq \
		--filter "name=${CONTAINER}" \
		--filter "status=paused" &> /dev/null; then
		docker unpause ${CONTAINER} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${CONTAINER}" \
		--filter "status=running" &> /dev/null; then
		docker stop ${CONTAINER} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${CONTAINER}" &> /dev/null; then
		docker rm -vf ${CONTAINER} &> /dev/null
	fi
}

function test_basic_operations ()
{
	local -r apache_load_modules_details=" - alias_module
 - authz_core_module
 - authz_user_module
 - deflate_module
 - dir_module
 - expires_module
 - filter_module
 - headers_module
 - log_config_module
 - mime_module
 - proxy_fcgi_module
 - proxy_module
 - setenvif_module
 - socache_shmcb_module
 - status_module
 - unixd_module
 - version_module"
	local -r required_apache_modules="
authz_core_module
authz_user_module
log_config_module
expires_module
deflate_module
filter_module
headers_module
setenvif_module
socache_shmcb_module
mime_module
status_module
dir_module
alias_module
unixd_module
version_module
proxy_module
proxy_fcgi_module
"
	local -r other_required_apache_modules="
core_module
so_module
http_module
authz_host_module
mpm_prefork_module
cgi_module
"
	local -r necessary_apache_modules="
${required_apache_modules}
${other_required_apache_modules}
"

	local all_loaded_apache_modules=""
	local apache_access_log_entry=""
	local apache_details_title=""
	local apache_document_root=""
	local apache_load_modules=""
	local apache_run_group=""
	local apache_run_user=""
	local apache_run_user_group=""
	local apache_server_alias=""
	local apache_server_mpm=""
	local apache_server_name=""
	local apache_system_user=""
	local container_hostname=""
	local container_port_80=""
	local curl_get_request=""
	local curl_session_name=""
	local header_server=""
	local header_x_service_uid=""
	local status=0

	describe "Basic Apache PHP operations"
		trap "__terminate_container apache-php.pool-1.1.1 &> /dev/null; \
		__destroy; \
		exit 1" \
			INT TERM EXIT

		__terminate_container \
			apache-php.pool-1.1.1 \
		&> /dev/null

		describe "Runs named container"
			docker run \
				--detach \
				--no-healthcheck \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			it "Can publish ${DOCKER_PORT_MAP_TCP_80}:80."
				container_port_80="$(
					__get_container_port \
						apache-php.pool-1.1.1 \
						80/tcp
				)"

				if [[ ${DOCKER_PORT_MAP_TCP_80} == 0 ]] \
					|| [[ -z ${DOCKER_PORT_MAP_TCP_80} ]]; then
					assert gt \
						"${container_port_80}" \
						"30000"
				else
					assert equal \
						"${container_port_80}" \
						"${DOCKER_PORT_MAP_TCP_80}"
				fi
			end
		end

		if ! __is_container_ready \
			apache-php.pool-1.1.1 \
			${STARTUP_TIME} \
			"/usr/sbin/httpd(\.worker|\.event)? " \
			"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
		then
			exit 1
		fi

		container_hostname="$(
			docker exec \
				apache-php.pool-1.1.1 \
				hostname
		)"

		describe "Response Headers"
			it "Sets Server to 'Apache'."
				header_server="$(
					curl -sI \
						--header "Host: ${container_hostname}" \
						http://127.0.0.1:${container_port_80} \
					| grep '^Server: ' \
					| cut -c 9- \
					| tr -d '\r'
				)"

				assert equal \
					"${header_server}" \
					"Apache"
			end

			it "Sets X-Service-UID to hostname."
				header_x_service_uid="$(
					curl -sI \
						--header "Host: ${container_hostname}" \
						http://127.0.0.1:${container_port_80} \
					| grep '^X-Service-UID: ' \
					| cut -c 16- \
					| tr -d '\r'
				)"

				assert equal \
					"${header_x_service_uid}" \
					"${container_hostname}"
			end
		end

		describe "Logging"
			it "Outputs Apache details."
				apache_details_title="$(
					docker logs \
						apache-php.pool-1.1.1 \
					| grep '^Apache Details' \
					| tr -d '\r'
				)"

				assert equal \
					"${apache_details_title}" \
					"Apache Details"
			end

			describe "Apache configuration details"
				it "Has default system user."
					apache_system_user="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^system user : ' \
						| cut -c 15- \
						| tr -d '\r'
					)"

					assert equal \
						"${apache_system_user}" \
						"app"
				end

				it "Has default run user."
					apache_run_user="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^run user : ' \
						| cut -c 12- \
						| tr -d '\r'
					)"

					assert equal \
						"${apache_run_user}" \
						"app-www"
				end

				it "Has default run group."
					apache_run_group="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^run group : ' \
						| cut -c 13- \
						| tr -d '\r'
					)"

					assert equal \
						"${apache_run_group}" \
						"app-www"
				end

				it "Has default server name."
					apache_server_name="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^server name : ' \
						| cut -c 15- \
						| tr -d '\r'
					)"

					assert equal \
						"${apache_server_name}" \
						"${container_hostname}"
				end

				it "Has default server alias."
					apache_server_alias="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^server alias : ' \
						| cut -c 16- \
						| tr -d '\r'
					)"

					assert equal \
						"${apache_server_alias}" \
						""
				end

				it "Has default X-Service-UID header."
					header_x_service_uid="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^header x-service-uid : ' \
						| cut -c 24- \
						| tr -d '\r'
					)"

					# {{HOSTNAME}} replaced
					assert equal \
						"${header_x_service_uid}" \
						"${container_hostname}"
				end

				it "Has default document root."
					apache_document_root="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^document root : ' \
						| cut -c 17- \
						| tr -d '\r' \
						| awk '{ print $1 }'
					)"

					# APACHE_CONTENT_ROOT/APACHE_PUBLIC_DIRECTORY
					assert equal \
						"${apache_document_root}" \
						"/var/www/app/public_html"
				end

				it "Has default server mpm."
					apache_server_mpm="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^server mpm : ' \
						| cut -c 13- \
						| tr -d '\r' \
						| awk '{ print tolower($1) }'
					)"

					assert equal \
						"${apache_server_mpm}" \
						"prefork"
				end

				it "Has default enabled modules."
					apache_load_modules="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| sed -ne \
							'/^modules enabled :/,/^--+$/ p' \
							| awk '/^ - /'
					)"

					assert equal \
						"${apache_load_modules}" \
						"${apache_load_modules_details}"
				end
			end

			describe "Access log (var/log/apache_access_log)"
				it "Gets updated."
					curl_get_request="$(
						curl -s \
							--header "Host: ${container_hostname}" \
							http://127.0.0.1:${container_port_80}
					)"

					apache_access_log_entry="$(
						docker exec \
							apache-php.pool-1.1.1 \
							tail -n 1 \
							/var/www/app/var/log/apache_access_log \
						| grep -oE \
							'"GET / HTTP/1\.1" 200' \
					)"

					assert equal \
						"${apache_access_log_entry}" \
						"\"GET / HTTP/1.1\" 200"
				end

				it "Has entries in combined LogFormat."
					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/www/app/var/log/apache_access_log \
					| grep -qE \
						'^.+ .+ .+ \[.+\] "GET / HTTP/1\.1" 200 .+ ".+" ".*"$' \
					&> /dev/null

					assert equal \
						"${?}" \
						0
				end
			end

			describe "Error log (var/log/apache_error_log)"
				it "Remains empty."
					curl_get_request="$(
						curl -s \
							--header "Host: ${container_hostname}" \
							http://127.0.0.1:${container_port_80}
					)"

					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/www/app/var/log/apache_error_log \
					&> /dev/null

					assert equal \
						"${?}" \
						0
				end
			end
		end

		describe "Apache server-status"
			it "Is accessible from localhost."
				docker exec \
					apache-php.pool-1.1.1 \
					curl -s \
						--header "Host: ${container_hostname}" \
						http://127.0.0.1/server-status\?auto \
				| grep -qE \
					'^Scoreboard: [\._SRWKDCLGI]+$' \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			it "Excludes ExtendedStatus information."
				docker exec \
					apache-php.pool-1.1.1 \
					curl -s \
						--header "Host: ${container_hostname}" \
						http://127.0.0.1/server-status\?auto \
				| grep -qE \
					'^Total Accesses: [0-9]+' \
				&> /dev/null

				assert equal \
					"${?}" \
					1
			end

			describe "Remote access"
				it "Is denied."
					curl -s \
						--header "Host: ${container_hostname}" \
						http://127.0.0.1:${container_port_80}/server-status\?auto \
					| grep -qE \
						'^Scoreboard: [\._SRWKDCLGI]+$' \
					&> /dev/null

					assert equal \
						"${?}" \
						1
				end

				it "Returns a 403 status code."
					curl_response_code="$(
						curl -s \
							-o /dev/null \
							-w "%{http_code}" \
							--header "Host: ${container_hostname}" \
							http://127.0.0.1:${container_port_80}/server-status\?auto
					)"

					assert equal \
						"${curl_response_code}" \
						"403"
				end
			end
		end

		describe "Apache modules"
			all_loaded_apache_modules="$(
				docker exec \
					apache-php.pool-1.1.1 \
					bash -c "apachectl -M 2>&1 \
						| sed -r \
							-e '/Loaded Modules:/d' \
							-e 's~^ *([0-9a-z_]*).*~\1~g'"
			)"

			it "Has all required."
				for module in ${required_apache_modules}; do
					grep -q "^${module}$" <<< "${all_loaded_apache_modules}"
					if [[ status=${?} -ne 0 ]]; then
						break
					fi
				done

				assert equal \
					"${status}" \
					0
			end

			it "Has only necessary."
				for module in ${all_loaded_apache_modules}; do
					grep -q "^${module}$" <<< "${necessary_apache_modules}"
					if [[ status=${?} -ne 0 ]]; then
						break
					fi
				done

				assert equal \
					"${status}" \
					0
			end
		end

		describe "Apache process runner"
			it "Is the service user:group."
				apache_run_user_group="$(
					docker exec \
						apache-php.pool-1.1.1 \
						ps axo user,group,comm \
					| grep httpd \
					| tail -n 1 \
					| awk '{ print $1":"$2 }'
				)"

				assert equal \
					"${apache_run_user_group}" \
					"app-www:app-www"
			end
		end

		describe "PHP options"
			it "Has default session.name."
				curl_session_name="$(
					curl -s \
						--header 'Host: localhost.localdomain' \
						http://127.0.0.1:${container_port_80}/_phpinfo.php \
						| grep 'session.name' \
						| sed -E \
							-e 's~^.*(session.name)~\1~' \
							-e 's~</t(r|d)>~~g' \
							-e 's~<td[^>]*>~ ~g'
				)"

				assert equal \
					"${curl_session_name}" \
					"session.name PHPSESSID PHPSESSID"
			end
		end

		__terminate_container \
			apache-php.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

function test_custom_configuration ()
{
	local -r session_store_alias="memcached_1"
	local -r session_store_network="bridge_internal_1"

	local apache_access_log_entry=""
	local apache_access_log_entry=""
	local apache_run_group=""
	local apache_ssl_cipher_suite=""
	local apache_system_user=""
	local certificate_fingerprint_file=""
	local certificate_fingerprint_server=""
	local certificate_pem_base64=""
	local cipher=""
	local cipher_match=""
	local container_port_80=""
	local container_port_443=""
	local curl_get_request=""
	local curl_response_code_default=""
	local curl_response_code_server_name=""
	local curl_response_code_server_alias=""
	local curl_session_data_write=""
	local curl_session_data_read=""
	local curl_session_name=""
	local header_x_service_operating_mode=""
	local header_x_service_uid=""
	local is_up=""
	local php_date_timezone=""
	local protocol=""

	describe "Customised Apache PHP configuration"
		trap "__terminate_container apache-php.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		describe "Access log"
			it "Sets common LogFormat."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--no-healthcheck \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_CUSTOM_LOG_FORMAT="common" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				container_port_80="$(
					__get_container_port \
						apache-php.pool-1.1.1 \
						80/tcp
				)"

				curl -s \
					--output /dev/null \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80}

				docker exec \
					apache-php.pool-1.1.1 \
					tail -n 1 \
					/var/www/app/var/log/apache_access_log \
				| grep -qE \
					'^.+ .+ .+ \[.+\] "GET / HTTP/1\.1" 200 .+$' \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			it "Sets a relative path."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--no-healthcheck \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_CUSTOM_LOG_LOCATION="var/log/access.log" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl -s \
					--output /dev/null \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80}

				apache_access_log_entry="$(
					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/www/app/var/log/access.log \
					| grep -oE \
						'"GET / HTTP/1\.1" 200' \
				)"

				assert equal \
					"${apache_access_log_entry}" \
					"\"GET / HTTP/1.1\" 200"
			end

			it "Sets an absolute path."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--no-healthcheck \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_CUSTOM_LOG_LOCATION="/var/log/httpd/access.log" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl -s \
					--output /dev/null \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80}

				apache_access_log_entry="$(
					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/log/httpd/access.log \
					| grep -oE \
						'"GET / HTTP/1\.1" 200' \
				)"

				assert equal \
					"${apache_access_log_entry}" \
					"\"GET / HTTP/1.1\" 200"
			end
		end

		describe "Error log"
			it "Sets a relative path."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_ERROR_LOG_LOCATION="var/log/error.log" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl -s \
					--output /dev/null \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80}

				docker exec \
					apache-php.pool-1.1.1 \
					tail -n 1 \
					/var/www/app/var/log/error.log \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			it "Sets an absolute path."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_ERROR_LOG_LOCATION="/var/log/httpd/error.log" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl -s \
					--output /dev/null \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80}

				docker exec \
					apache-php.pool-1.1.1 \
					tail -n 1 \
					/var/log/httpd/error.log \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			it "Sets log level (e.g debug)."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_ERROR_LOG_LEVEL="debug" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl -s \
					--output /dev/null \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80}

				docker exec \
					apache-php.pool-1.1.1 \
					tail -n 1 \
					/var/www/app/var/log/apache_error_log \
				| grep -qE \
					' \[(.+:)?debug\] ' \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end
		end

		describe "Apache ExtendedStatus enabled"
			it "Is accessible from localhost."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_EXTENDED_STATUS_ENABLED="true" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				docker exec \
					apache-php.pool-1.1.1 \
					curl -s \
						--header "Host: app-1.local" \
						http://127.0.0.1/server-status\?auto \
				| grep -qE \
					'^Total Accesses: [0-9]+' \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			describe "Remote access"
				it "Is denied."
					curl -s \
						--header "Host: app-1.local" \
						http://127.0.0.1:${container_port_80}/server-status\?auto \
					| grep -qE \
						'^Total Accesses: [0-9]+' \
					&> /dev/null

					assert equal \
						"${?}" \
						1
				end

				it "Returns a 403 status code."
					curl_response_code="$(
						curl -s \
							-o /dev/null \
							-w "%{http_code}" \
							--header "Host: app-1.local" \
							http://127.0.0.1:${container_port_80}/server-status\?auto
					)"

					assert equal \
						"${curl_response_code}" \
						"403"
				end
			end
		end

		describe "X-Service-UID response header."
			it "Sets a static value."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_HEADER_X_SERVICE_UID="host-name@1.2" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				header_x_service_uid="$(
					curl -sI \
						--header "Host: app-1.local" \
						http://127.0.0.1:${container_port_80} \
					| grep '^X-Service-UID: ' \
					| cut -c 16- \
					| tr -d '\r'
				)"

				assert equal \
					"${header_x_service_uid}" \
					"host-name@1.2"
			end

			it "Replaces {{HOSTNAME}}."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_HEADER_X_SERVICE_UID="{{HOSTNAME}}:${DOCKER_PORT_MAP_TCP_80}" \
					--hostname app-1.local \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				header_x_service_uid="$(
					curl -sI \
						--header "Host: app-1.local" \
						http://127.0.0.1:${container_port_80} \
					| grep '^X-Service-UID: ' \
					| cut -c 16- \
					| tr -d '\r'
				)"

				assert equal \
					"${header_x_service_uid}" \
					"app-1.local:${DOCKER_PORT_MAP_TCP_80}"
			end
		end

		describe "Loading Apache modules"
			it "Adds rewrite_module."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--env APACHE_LOAD_MODULES="rewrite_module" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				docker exec \
					apache-php.pool-1.1.1 \
					bash -c "apachectl -M 2>&1 | grep -q rewrite_module"

				assert equal \
					"${?}" \
					0
			end
		end

		describe "Server MPM"
			it "Sets event MPM."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--env APACHE_MPM="event" \
					--hostname app-1.local \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				docker exec \
					apache-php.pool-1.1.1 \
					bash -c "apachectl -V 2>&1 | grep -qiE '^Server MPM:[ ]+event$'"

				assert equal \
					"${?}" \
					0
			end
		end

		describe "Operating mode (i.e -D <internal variable>)"
			it "Sets to development."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_OPERATING_MODE="development" \
					--hostname app-1.local \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				header_x_service_operating_mode="$(
					curl -sI \
						--header "Host: app-1.local" \
						http://127.0.0.1:${container_port_80} \
					| grep '^X-Service-Operating-Mode: ' \
					| cut -c 27- \
					| tr -d '\r'
				)"

				assert equal \
					"${header_x_service_operating_mode}" \
					"development"
			end
		end

		describe "System user (i.e. application owner)"
			it "Sets name to 'app-user'."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--env APACHE_SYSTEM_USER="app-user" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				apache_system_user="$(
					docker exec \
						apache-php.pool-1.1.1 \
						stat -c '%U' /var/www/app/public_html
				)"

				assert equal \
					"${apache_system_user}" \
					"app-user"
			end
		end

		describe "Process runner"
			it "Sets user."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--env APACHE_RUN_USER="runner" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				apache_run_user="$(
					docker exec \
						apache-php.pool-1.1.1 \
						ps axo user,group,comm \
					| grep httpd \
					| tail -n 1 \
					| awk '{ print $1 }'
				)"

				assert equal \
					"${apache_run_user}" \
					"runner"
			end

			it "Sets group."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--env APACHE_RUN_GROUP="runners" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				apache_run_group="$(
					docker exec \
						apache-php.pool-1.1.1 \
						ps axo user,group,comm \
					| grep httpd \
					| tail -n 1 \
					| awk '{ print $2 }'
				)"

				assert equal \
					"${apache_run_group}" \
					"runners"
			end
		end

		describe "Apache ServerName/ServerAlias"
			it "Sets a static ServerName."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_SERVER_NAME="app-1.local" \
					--env APACHE_SERVER_ALIAS="www.app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				# Add a default VirtualHost that rejects access (403 response).
				docker exec -i \
					apache-php.pool-1.1.1 \
					tee \
						/etc/services-config/httpd/conf.d/05-virtual-host.conf \
						1> /dev/null \
						<<-CONFIG
				<VirtualHost *:80 *:8443>
				    ServerName localhost.localdomain
				    DocumentRoot /var/www/html

				    <Directory /var/www/html>
				        ErrorDocument 403 "403 Forbidden"
				        <IfVersion < 2.4>
				            Order deny,allow
				            Deny from all
				        </IfVersion>
				        <IfVersion >= 2.4>
				            Require all denied
				        </IfVersion>
				    </Directory>
				</VirtualHost>
				CONFIG

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				docker exec \
					apache-php.pool-1.1.1 \
					bash -c 'apachectl graceful'

				curl_response_code_default="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						http://127.0.0.1:${container_port_80}
				)"

				curl_response_code_server_name="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						--header "Host: app-1.local" \
						http://127.0.0.1:${container_port_80}
				)"

				assert equal \
					"${curl_response_code_default}:${curl_response_code_server_name}" \
					"403:200"
			end

			it "Sets a static ServerAlias."
				curl_response_code_server_alias="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						--header 'Host: www.app-1.local' \
						http://127.0.0.1:${container_port_80}
				)"

				assert equal \
					"${curl_response_code_server_alias}" \
					"200"
			end
		end

		describe "Apache ServerName"
			it "Is container hostname."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--hostname php-hello-world \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				# Add a default VirtualHost that rejects access (403 response).
				docker exec -i \
					apache-php.pool-1.1.1 \
					tee \
						/etc/services-config/httpd/conf.d/05-virtual-host.conf \
						1> /dev/null \
						<<-CONFIG
				<VirtualHost *:80 *:8443>
				    ServerName localhost.localdomain
				    DocumentRoot /var/www/html

				    <Directory /var/www/html>
				        ErrorDocument 403 "403 Forbidden"
				        <IfVersion < 2.4>
				            Order deny,allow
				            Deny from all
				        </IfVersion>
				        <IfVersion >= 2.4>
				            Require all denied
				        </IfVersion>
				    </Directory>
				</VirtualHost>
				CONFIG

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				docker exec \
					apache-php.pool-1.1.1 \
					bash -c 'apachectl graceful'

				curl_response_code_default="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						http://127.0.0.1:${container_port_80}
				)"

				curl_response_code_server_name="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						--header 'Host: php-hello-world' \
						http://127.0.0.1:${container_port_80}
				)"

				assert equal \
					"${curl_response_code_default}:${curl_response_code_server_name}" \
					"403:200"
			end

			it "Replaces {{HOSTNAME}}."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--hostname php-hello-world \
					--env APACHE_SERVER_NAME="{{HOSTNAME}}.localdomain" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				# Add a default VirtualHost that rejects access (403 response).
				docker exec -i \
					apache-php.pool-1.1.1 \
					tee \
						/etc/services-config/httpd/conf.d/05-virtual-host.conf \
						1> /dev/null \
						<<-CONFIG
				<VirtualHost *:80 *:8443>
				    ServerName localhost.localdomain
				    DocumentRoot /var/www/html

				    <Directory /var/www/html>
				        ErrorDocument 403 "403 Forbidden"
				        <IfVersion < 2.4>
				            Order deny,allow
				            Deny from all
				        </IfVersion>
				        <IfVersion >= 2.4>
				            Require all denied
				        </IfVersion>
				    </Directory>
				</VirtualHost>
				CONFIG

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				docker exec \
					apache-php.pool-1.1.1 \
					bash -c 'apachectl graceful'

				curl_response_code_default="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						http://127.0.0.1:${container_port_80}
				)"

				curl_response_code_server_name="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						--header 'Host: php-hello-world.localdomain' \
						http://127.0.0.1:${container_port_80}
				)"

				assert equal \
					"${curl_response_code_default}:${curl_response_code_server_name}" \
					"403:200"
			end
		end

		describe "Apache ServerAlias"
			it "Replaces {{HOSTNAME}}."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--hostname php-hello-world \
					--env APACHE_SERVER_ALIAS="{{HOSTNAME}}.localdomain" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				# Add a default VirtualHost that rejects access (403 response).
				docker exec -i \
					apache-php.pool-1.1.1 \
					tee \
						/etc/services-config/httpd/conf.d/05-virtual-host.conf \
						1> /dev/null \
						<<-CONFIG
				<VirtualHost *:80 *:8443>
				    ServerName localhost.localdomain
				    DocumentRoot /var/www/html

				    <Directory /var/www/html>
				        ErrorDocument 403 "403 Forbidden"
				        <IfVersion < 2.4>
				            Order deny,allow
				            Deny from all
				        </IfVersion>
				        <IfVersion >= 2.4>
				            Require all denied
				        </IfVersion>
				    </Directory>
				</VirtualHost>
				CONFIG

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				docker exec \
					apache-php.pool-1.1.1 \
					bash -c 'apachectl graceful'

				curl_response_code_default="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						http://127.0.0.1:${container_port_80}
				)"

				curl_response_code_server_name="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						--header 'Host: php-hello-world.localdomain' \
						http://127.0.0.1:${container_port_80}
				)"

				assert equal \
					"${curl_response_code_default}:${curl_response_code_server_name}" \
					"403:200"
			end
		end

		describe "Apache public directory"
			it "Sets to 'web'."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_PUBLIC_DIRECTORY="web" \
					--hostname app-1.local \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				# For the server to start, the public directory needs to match that
				# which is being configured for the test.
				docker exec \
					apache-php.pool-1.1.1 \
					mv /opt/app/public_html /opt/app/web

				docker restart \
					apache-php.pool-1.1.1 \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl -sI \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80} \
				| grep -q '^X-Service-UID: app-1.local' \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end
		end

		describe "Package path"
			it "Can be changed."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_SERVER_NAME="app-1.local" \
					--env PACKAGE_PATH="/opt/php-hw" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				# For the server to start, the package directory needs to exist.
				docker exec \
					apache-php.pool-1.1.1 \
					mkdir -p -m 750 /opt/php-hw/{public_html,var/{log,tmp}}

				docker exec -i \
					apache-php.pool-1.1.1 \
					tee \
						/opt/php-hw/public_html/index.php \
						1> /dev/null \
						<<-EOT
				<?php
				    header(
				        'Content-Type: text/plain; charset=utf-8'
				    );
				    print 'Hello, world!';
				EOT

				docker exec \
					apache-php.pool-1.1.1 \
					chown -R app:app-www /opt/php-hw

				docker exec \
					apache-php.pool-1.1.1 \
					find /opt/php-hw -type d -exec chmod 750 {} +

				docker exec \
					apache-php.pool-1.1.1 \
					find /opt/php-hw/var -type d -exec chmod 770 {} +

				docker exec \
					apache-php.pool-1.1.1 \
					find /opt/php-hw -type f -exec chmod 640 {} +

				docker restart \
					apache-php.pool-1.1.1 \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl -s \
					--header "Host: app-1.local" \
					http://127.0.0.1:${container_port_80} \
				| grep -q '^Hello, world!' \
				&> /dev/null

				assert equal \
					"${?}" \
					0
			end
		end

		describe "SSL/TLS (i.e. ssl_module)"
			it "Can publish ${DOCKER_PORT_MAP_TCP_443}:443."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
					--env APACHE_MOD_SSL_ENABLED="true" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				container_port_443="$(
					__get_container_port \
						apache-php.pool-1.1.1 \
						443/tcp
				)"

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				curl_response_code="$(
					curl -ks \
						-o /dev/null \
						-w "%{http_code}" \
						--header "Host: app-1.local" \
						https://127.0.0.1:${container_port_443}
				)"

				assert equal \
					"${curl_response_code}" \
					"200"
			end

			describe "Static certificate."
				if [[ -s /tmp/www.app-1.local.pem ]]; then
					certificate_fingerprint_file="$(
						cat \
							/tmp/www.app-1.local.pem \
						| sed \
							-n \
							-e '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' \
						| openssl x509 \
							-fingerprint \
							-noout \
						| sed \
							-e 's~SHA1 Fingerprint=~~'
					)"

					if [[ $(uname) == "Darwin" ]]; then
						certificate_pem_base64="$(
							base64 \
								-i /tmp/www.app-1.local.pem
						)"
					else
						certificate_pem_base64="$(
							base64 \
								-w 0 \
								-i /tmp/www.app-1.local.pem
						)"
					fi
				fi

				it "Sets from base64 encoded value."
					__terminate_container \
						apache-php.pool-1.1.1 \
					&> /dev/null

					docker run \
						--detach \
						--name apache-php.pool-1.1.1 \
						--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
						--env APACHE_MOD_SSL_ENABLED="true" \
						--env APACHE_SERVER_NAME="www.app-1.local" \
						--env APACHE_SSL_CERTIFICATE="${certificate_pem_base64}" \
						jdeathe/centos-ssh-apache-php:latest \
					&> /dev/null

					container_port_443="$(
						__get_container_port \
							apache-php.pool-1.1.1 \
							443/tcp
					)"

					if ! __is_container_ready \
						apache-php.pool-1.1.1 \
						${STARTUP_TIME} \
						"/usr/sbin/httpd(\.worker|\.event)? " \
						"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
					then
						exit 1
					fi

					certificate_fingerprint_server="$(
						echo -n \
						| openssl s_client \
							-connect 127.0.0.1:${container_port_443} \
							-CAfile /tmp/www.app-1.local.pem \
							-nbio \
							2>&1 \
						| sed \
							-n \
							-e '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' \
						| openssl \
							x509 \
							-fingerprint \
							-noout \
						| sed \
							-e 's~SHA1 Fingerprint=~~'
					)"

					assert equal \
						"${certificate_fingerprint_server}" \
						"${certificate_fingerprint_file}"
				end

				it "Sets from file path value."
					__terminate_container \
						apache-php.pool-1.1.1 \
					&> /dev/null

					docker run \
						--detach \
						--name apache-php.pool-1.1.1 \
						--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
						--env APACHE_MOD_SSL_ENABLED="true" \
						--env APACHE_SERVER_NAME="www.app-1.local" \
						--env APACHE_SSL_CERTIFICATE="/var/run/tmp/www.app-1.local.pem" \
						--volume /tmp:/var/run/tmp:ro \
						jdeathe/centos-ssh-apache-php:latest \
					&> /dev/null

					container_port_443="$(
						__get_container_port \
							apache-php.pool-1.1.1 \
							443/tcp
					)"

					if ! __is_container_ready \
						apache-php.pool-1.1.1 \
						${STARTUP_TIME} \
						"/usr/sbin/httpd(\.worker|\.event)? " \
						"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
					then
						exit 1
					fi

					certificate_fingerprint_server="$(
						echo -n \
						| openssl s_client \
							-connect 127.0.0.1:${container_port_443} \
							-CAfile /tmp/www.app-1.local.pem \
							-nbio \
							2>&1 \
						| sed \
							-n \
							-e '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' \
						| openssl \
							x509 \
							-fingerprint \
							-noout \
						| sed \
							-e 's~SHA1 Fingerprint=~~'
					)"

					assert equal \
						"${certificate_fingerprint_server}" \
						"${certificate_fingerprint_file}"
				end
			end

			it "Sets cipher suite."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
					--env APACHE_MOD_SSL_ENABLED="true" \
					--env APACHE_SERVER_NAME="www.app-1.local" \
					--env APACHE_SSL_CERTIFICATE="${certificate_pem_base64}" \
					--env APACHE_SSL_CIPHER_SUITE="DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				container_port_443="$(
					__get_container_port \
						apache-php.pool-1.1.1 \
						443/tcp
				)"

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				apache_ssl_cipher_suite=""
				for cipher in DHE-RSA-AES128-SHA DHE-RSA-AES256-SHA EDH-RSA-DES-CBC3-SHA; do
					cipher_match="$(
						echo -n \
						| openssl s_client \
							-cipher "${cipher}" \
							-connect 127.0.0.1:${container_port_443} \
							-CAfile /tmp/www.app-1.local.pem \
							-nbio \
							2>&1 \
						| grep -o "^[ ]*Cipher[ ]*: ${cipher}$" \
						| awk '{ print $3 }'
					)"

					if [[ -n ${cipher_match} ]]; then
						if [[ -n ${apache_ssl_cipher_suite} ]]; then
							apache_ssl_cipher_suite+=":"
						fi
						apache_ssl_cipher_suite+="${cipher_match}"
					fi
				done

				assert equal \
					"${apache_ssl_cipher_suite}" \
					"DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA"
			end

			it "Sets protocol (e.g TLSv1.2)."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
					--env APACHE_MOD_SSL_ENABLED="true" \
					--env APACHE_SERVER_NAME="www.app-1.local" \
					--env APACHE_SSL_CERTIFICATE="${certificate_pem_base64}" \
					--env APACHE_SSL_CIPHER_SUITE="DHE-RSA-AES128-SHA" \
					--env APACHE_SSL_PROTOCOL="all -SSLv3 -TLSv1 -TLSv1.1" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				container_port_443="$(
					__get_container_port \
						apache-php.pool-1.1.1 \
						443/tcp
				)"

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				apache_ssl_cipher_suite=""
				for protocol in ssl3 tls1 tls1_1 tls1_2; do
					cipher_match="$(
						echo -n \
						| openssl s_client \
							-${protocol} \
							-connect 127.0.0.1:${container_port_443} \
							-CAfile /tmp/www.app-1.local.pem \
							-nbio \
							2>&1 \
						| grep -o "^[ ]*Cipher[ ]*: .*$" \
						| awk '{ print $3 }'
					)"

					if [[ -n ${cipher_match} ]]; then
						if [[ -n ${apache_ssl_cipher_suite} ]]; then
							apache_ssl_cipher_suite+=":"
						fi
						apache_ssl_cipher_suite+="${cipher_match}"
					fi
				done

				assert equal \
					"${apache_ssl_cipher_suite}" \
					"0000:0000:0000:DHE-RSA-AES128-SHA"
			end
		end

		describe "Configure autostart"
			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name apache-php.pool-1.1.1 \
				--env APACHE_AUTOSTART_HTTPD_BOOTSTRAP=false \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${STARTUP_TIME}

			# Healthcheck should fail unless running PHP-FPM without Apache.
			it "Can disable httpd-bootstrap."
				is_up="1"

				docker ps \
					--quiet \
					--filter "name=apache-php.pool-1.1.1" \
					--filter "health=unhealthy" \
				&> /dev/null
				is_up="${?}"

				docker top \
					apache-php.pool-1.1.1 \
				&> /dev/null \
				| grep -qE '/usr/sbin/httpd(\.worker|\.event)? '

				assert equal \
					"${is_up}:${?}" \
					"0:1"
			end

			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name apache-php.pool-1.1.1 \
				--env APACHE_AUTOSTART_HTTPD_WRAPPER=false \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${STARTUP_TIME}

			it "Can disable httpd-wrapper."
				is_up="1"

				docker ps \
					--filter "name=apache-php.pool-1.1.1" \
					--filter "health=healthy" \
				&> /dev/null
				is_up="${?}"

				docker top \
					apache-php.pool-1.1.1 \
				&> /dev/null \
				| grep -qE '/usr/sbin/httpd(\.worker|\.event)? '

				assert equal \
					"${is_up}:${?}" \
					"0:1"
			end

			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name apache-php.pool-1.1.1 \
				--env APACHE_AUTOSTART_PHP_FPM_WRAPPER=false \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${STARTUP_TIME}

			# Healthcheck should fail unless there's a static HTML file to serve up.
			it "Can disable php-fpm-wrapper."
				is_up="1"

				docker ps \
					--filter "name=apache-php.pool-1.1.1" \
					--filter "health=unhealthy" \
				&> /dev/null
				is_up="${?}"

				docker top \
					apache-php.pool-1.1.1 \
				&> /dev/null \
				| grep -qE 'php-fpm: pool app-www[ ]*$'

				assert equal \
					"${is_up}:${?}" \
					"0:1"
			end

			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null
		end

		describe "PHP date.timezone"
			it "Sets to 'Europe/London'."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env PHP_OPTIONS_DATE_TIMEZONE="Europe/London" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					${STARTUP_TIME} \
					"/usr/sbin/httpd(\.worker|\.event)? " \
					"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
				then
					exit 1
				fi

				php_date_timezone="$(
					docker exec \
						apache-php.pool-1.1.1 \
						php \
							-r \
							"printf('%s', ini_get('date.timezone'));"
				)"

				assert equal \
					"${php_date_timezone}" \
					"Europe/London"
			end
		end

		describe "PHP session.name"
			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env PHP_OPTIONS_SESSION_NAME="app-session" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			if ! __is_container_ready \
				apache-php.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/httpd(\.worker|\.event)? " \
				"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
			then
				exit 1
			fi

			container_port_80="$(
				__get_container_port \
					apache-php.pool-1.1.1 \
					80/tcp
			)"

			it "Sets to app-session."
				curl_session_name="$(
					curl -s \
						--header 'Host: localhost.localdomain' \
						http://127.0.0.1:${container_port_80}/_phpinfo.php \
						| grep 'session.name' \
						| sed -E \
							-e 's~^.*(session.name)~\1~' \
							-e 's~</t(r|d)>~~g' \
							-e 's~<td[^>]*>~ ~g'
				)"

				assert equal \
					"${curl_session_name}" \
					"session.name app-session app-session"
			end

			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null
		end

		describe "PHP memcached session store"
			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env PHP_OPTIONS_SESSION_SAVE_HANDLER="memcached" \
				--env PHP_OPTIONS_SESSION_SAVE_PATH="${session_store_alias}:11211" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			docker network connect \
				${session_store_network} \
				apache-php.pool-1.1.1

			if ! __is_container_ready \
				apache-php.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/httpd(\.worker|\.event)? " \
				"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
			then
				exit 1
			fi

			# Create scripts that write / read session data.
			docker exec \
				apache-php.pool-1.1.1 \
				mkdir -p -m 750 /opt/app/public_html/session

			docker exec -i \
				apache-php.pool-1.1.1 \
				tee \
					/opt/app/public_html/session/write.php \
					1> /dev/null \
					<<-EOT
			<?php
				session_start();
				\$_SESSION['integer'] = 123;
				\$_SESSION['float'] = 12345.67890;
				\$_SESSION['string'] = '@memcached:#\$£';
				session_write_close();
				var_dump(\$_SESSION);
			EOT

			docker exec -i \
				apache-php.pool-1.1.1 \
				tee \
					/opt/app/public_html/session/read.php \
					1> /dev/null \
					<<-EOT
			<?php
				session_start();
				var_dump(\$_SESSION);
			EOT

			docker exec \
				apache-php.pool-1.1.1 \
				chown -R app:app-www /opt/app/public_html/session

			docker exec \
				apache-php.pool-1.1.1 \
				find /opt/app/public_html/session -type d -exec chmod 750 {} +

			docker exec \
				apache-php.pool-1.1.1 \
				find /opt/app/public_html/session -type f -exec chmod 640 {} +

			docker restart \
				apache-php.pool-1.1.1 \
			&> /dev/null

			if ! __is_container_ready \
				apache-php.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/httpd(\.worker|\.event)? " \
				"[[ 000 != \$(curl -sI -o /dev/null -w %{http_code} localhost/) ]]"
			then
				exit 1
			fi

			container_port_80="$(
				__get_container_port \
					apache-php.pool-1.1.1 \
					80/tcp
			)"

			describe "Session Cookies"
				it "Start empty."
					curl_session_data_read="$(
						curl -s \
							--header 'Host: localhost.localdomain' \
							--cookie ~/.curl_cookies \
							--cookie-jar ~/.curl_cookies \
							http://127.0.0.1:${container_port_80}/session/read.php
					)"

					assert equal \
						"${curl_session_data_read}" \
						'array(0) {
}'
				end

				it "Can write data."
					curl_session_data_write="$(
						curl -s \
							--header 'Host: localhost.localdomain' \
							--cookie ~/.curl_cookies \
							--cookie-jar ~/.curl_cookies \
							http://127.0.0.1:${container_port_80}/session/write.php
					)"

					assert unequal \
						"${curl_session_data_write}" \
						""
				end

				it "Can read data."
					curl_session_data_read="$(
						curl -s \
							--header 'Host: localhost.localdomain' \
							--cookie ~/.curl_cookies \
							--cookie-jar ~/.curl_cookies \
							http://127.0.0.1:${container_port_80}/session/read.php
					)"

					assert unequal \
						"${curl_session_data_read}" \
						""
				end

				it "Persists data."
					assert equal \
						"${curl_session_data_read}" \
						'array(3) {
  ["integer"]=>
  int(123)
  ["float"]=>
  float(12345.6789)
  ["string"]=>
  string(15) "@memcached:#$£"
}'
				end
			end

			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null
		end

		trap - \
			INT TERM EXIT
	end
}

function test_healthcheck ()
{
	local -r interval_seconds=1
	local -r retries=10
	local health_status=""

	describe "Healthcheck"
		trap "__terminate_container apache-php.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		describe "Default configuration"
			__terminate_container \
				apache-php.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name apache-php.pool-1.1.1 \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			it "Returns a valid status on starting."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						apache-php.pool-1.1.1
				)"

				assert __shpec_matcher_egrep \
					"${health_status}" \
					"\"(starting|healthy|unhealthy)\""
			end

			sleep $(
				awk \
					-v interval_seconds="${interval_seconds}" \
					-v startup_time="${STARTUP_TIME}" \
					'BEGIN { print 1 + interval_seconds + startup_time; }'
			)

			it "Returns healthy after startup."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						apache-php.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"healthy\""
			end

			it "Returns unhealthy on failure."
				# sshd-wrapper failure
				docker exec -t \
					apache-php.pool-1.1.1 \
					bash -c "mv \
						/usr/sbin/httpd \
						/usr/sbin/httpd2" \
				&& docker exec -t \
					apache-php.pool-1.1.1 \
					bash -c "if [[ -n \$(pgrep -f '^/usr/sbin/httpd ') ]]; then \
						kill -9 \$(pgrep -f '^/usr/sbin/httpd '); \
					fi"

				sleep $(
					awk \
						-v interval_seconds="${interval_seconds}" \
						-v retries="${retries}" \
						'BEGIN { print 1 + interval_seconds * retries; }'
				)

				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						apache-php.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"unhealthy\""
			end
		end

		__terminate_container \
			apache-php.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

if [[ ! -d ${TEST_DIRECTORY} ]]; then
	printf -- \
		"ERROR: Please run from the project root.\n" \
		>&2
	exit 1
fi

describe "jdeathe/centos-ssh-apache-php:latest"
	__destroy
	__setup
	test_basic_operations
	test_custom_configuration
	test_healthcheck
	__destroy
end