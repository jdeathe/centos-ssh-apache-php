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
	:
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

function __is_container_ready ()
{
	local container="${1:-}"
	local process_pattern="${2:-}"
	local counter=$(
		awk \
			-v seconds="${3:-10}" \
			'BEGIN { print 10 * seconds; }'
	)

	until (( counter == 0 )); do
		sleep 0.1

		if docker exec ${container} \
			bash -c "ps axo command" \
			| grep -qE "${process_pattern}" \
			> /dev/null 2>&1 \
			&& [[ 000 != $(docker exec ${container} \
				bash -c "curl -sI -o /dev/null -w %{http_code} localhost/") ]]
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
	local readonly apache_load_modules_details=" - alias_module
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
	local readonly required_apache_modules="
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
	local readonly other_required_apache_modules="
core_module
so_module
http_module
authz_host_module
mpm_prefork_module
cgi_module
"
	local readonly necessary_apache_modules="
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
	local header_server=""
	local header_x_service_uid=""
	local status=0

	describe "Basic Apache PHP operations"
		trap "__terminate_container apache-php.pool-1.1.1 &> /dev/null; exit 1" \
			INT TERM EXIT

		__terminate_container \
			apache-php.pool-1.1.1 \
		&> /dev/null

		describe "Runs named container"
			docker run \
				--detach \
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
			"/usr/sbin/httpd(\.worker)? "; then
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

				# TODO This is included in the logs but not included in the Apache Details.
				it "Has default server mpm."
					apache_server_mpm="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep -o 'Apache Server MPM: .*$' \
						| cut -c 20- \
						| awk '{ print tolower($0) }' \
						| tr -d '\r'
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
							-e 's~^ *([a-z_]*).*~\1~g'"
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

		__terminate_container \
			apache-php.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

function test_custom_configuration ()
{
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
	local header_x_service_operating_mode=""
	local header_x_service_uid=""
	local php_date_timezone=""
	local protocol=""

	describe "Customised Apache PHP configuration"
		trap "__terminate_container apache-php.pool-1.1.1 &> /dev/null; exit 1" \
			INT TERM EXIT

		describe "Access log"
			it "Sets common LogFormat."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

				docker run \
					--detach \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_CUSTOM_LOG_FORMAT="common" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					"/usr/sbin/httpd(\.worker)? "; then
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
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_CUSTOM_LOG_LOCATION="var/log/access.log" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					"/usr/sbin/httpd(\.worker)? "; then
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
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_CUSTOM_LOG_LOCATION="/var/log/httpd/access.log" \
					--env APACHE_SERVER_NAME="app-1.local" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					--env APACHE_LOAD_MODULES="authz_core_module authz_user_module log_config_module expires_module deflate_module filter_module headers_module setenvif_module socache_shmcb_module mime_module status_module dir_module alias_module unixd_module version_module proxy_module proxy_fcgi_module rewrite_module" \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				if ! __is_container_ready \
					apache-php.pool-1.1.1 \
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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

			it "Sets static certificate."
				__terminate_container \
					apache-php.pool-1.1.1 \
				&> /dev/null

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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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
					"/usr/sbin/httpd(\.worker)? "; then
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

		__terminate_container \
			apache-php.pool-1.1.1 \
		&> /dev/null

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
					'BEGIN { print interval_seconds + startup_time; }'
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