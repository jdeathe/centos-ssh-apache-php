readonly BOOTSTRAP_BACKOFF_TIME=3
readonly DOCKER_HOSTNAME="localhost"
readonly TEST_DIRECTORY="test"

# These should ideally be a static value but hosts might be using this port so 
# need to allow for alternatives.
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-NULL}"
DOCKER_PORT_MAP_TCP_80="${DOCKER_PORT_MAP_TCP_80:-8080}"
DOCKER_PORT_MAP_TCP_443="${DOCKER_PORT_MAP_TCP_443:-9443}"
DOCKER_PORT_MAP_TCP_8443="${DOCKER_PORT_MAP_TCP_8443:-NULL}"

function docker_terminate_container ()
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

function test_setup ()
{
	return 0
}

if [[ ! -d ${TEST_DIRECTORY} ]]; then
	printf -- \
		"ERROR: Please run from the project root.\n" \
		>&2
	exit 1
fi

describe "jdeathe/centos-ssh-apache-php:latest"
	test_setup

	describe "Basic Apache PHP operations"
		trap "docker_terminate_container apache-php.pool-1.1.1 &> /dev/null" \
			INT TERM EXIT

		docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

		it "Runs an Apache PHP container named apache-php.pool-1.1.1 on port ${DOCKER_PORT_MAP_TCP_80}."
			local container_hostname=""
			local container_port_80=""
			local header_server=""
			local header_x_service_uid=""

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				jdeathe/centos-ssh-apache-php:latest &> /dev/null

			container_hostname="$(
				docker exec \
					apache-php.pool-1.1.1 \
					hostname
			)"

			container_port_80="$(
				docker port \
					apache-php.pool-1.1.1 \
					80/tcp
			)"
			container_port_80=${container_port_80##*:}

			if [[ ${DOCKER_PORT_MAP_TCP_80} == 0 ]] \
				|| [[ -z ${DOCKER_PORT_MAP_TCP_80} ]]; then
				assert gt "${container_port_80}" "30000"
			else
				assert equal "${container_port_80}" "${DOCKER_PORT_MAP_TCP_80}"
			fi

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			it "Responds with a Server header of 'Apache' only."
				header_server="$(
					curl -sI \
						--header 'Host: app-1.local' \
						http://127.0.0.1:${container_port_80} \
					| grep '^Server: ' \
					| cut -c 9- \
					| tr -d '\r'
				)"

				assert equal "${header_server}" "Apache"
			end

			it "Responds with a X-Service-UID header of the container hostname."
				header_x_service_uid="$(
					curl -sI \
						--header 'Host: app-1.local' \
						http://127.0.0.1:${container_port_80} \
					| grep '^X-Service-UID: ' \
					| cut -c 16- \
					| tr -d '\r'
				)"

				assert equal "${header_x_service_uid}" "${container_hostname}"
			end

			it "Outputs Apache Details in the docker logs."
				local apache_details_title=""

				apache_details_title="$(
					docker logs \
						apache-php.pool-1.1.1 \
					| grep '^Apache Details' \
					| tr -d '\r'
				)"

				assert equal "${apache_details_title}" "Apache Details"

				it "Includes the system user default (app)."
					local apache_system_user=""

					apache_system_user="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^system user : ' \
						| cut -c 15- \
						| tr -d '\r'
					)"

					assert equal "${apache_system_user}" "app"
				end

				it "Includes the run user default (app-www)."
					local apache_run_user=""

					apache_run_user="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^run user : ' \
						| cut -c 12- \
						| tr -d '\r'
					)"

					assert equal "${apache_run_user}" "app-www"
				end

				it "Includes the run group default (app-www)."
					local apache_run_group=""

					apache_run_group="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^run group : ' \
						| cut -c 13- \
						| tr -d '\r'
					)"

					assert equal "${apache_run_group}" "app-www"
				end

				it "Includes the server name default (app-1.local)."
					local apache_server_name=""

					apache_server_name="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^server name : ' \
						| cut -c 15- \
						| tr -d '\r'
					)"

					assert equal "${apache_server_name}" "app-1.local"
				end

				it "Includes the server alias default (EMPTY)."
					local apache_server_alias=""

					apache_server_alias="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^server alias : ' \
						| cut -c 16- \
						| tr -d '\r'
					)"

					assert equal "${apache_server_alias}" ""
				end

				it "Includes the header x-service-uid default ({{HOSTNAME}} replacement)."
					local apache_header_x_service_uid=""

					apache_header_x_service_uid="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^header x-service-uid : ' \
						| cut -c 24- \
						| tr -d '\r'
					)"

					assert equal "${apache_header_x_service_uid}" "${container_hostname}"
				end

				it "Includes the default document root APACHE_CONTENT_ROOT/APACHE_PUBLIC_DIRECTORY (/var/www/app/public_html)."
					local apache_document_root=""

					apache_document_root="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep '^document root : ' \
						| cut -c 17- \
						| tr -d '\r' \
						| awk '{ print $1 }'
					)"

					assert equal "${apache_document_root}" "/var/www/app/public_html"
				end

				# TODO This is included in the logs but not included in the Apache Details.
				it "Includes the server mpm default (prefork)."
					local apache_server_mpm=""

					apache_server_mpm="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| grep -o 'Apache Server MPM: .*$' \
						| cut -c 20- \
						| awk '{ print tolower($0) }' \
						| tr -d '\r'
					)"

					assert equal "${apache_server_mpm}" "prefork"
				end

				it "Includes the default modules enabled."
					local apache_load_modules=""
					local apache_load_modules_details=" - alias_module
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

					apache_load_modules="$(
						docker logs \
							apache-php.pool-1.1.1 \
						| sed -ne \
							'/^modules enabled :/,/^--+$/ p' \
							| awk '/^ - /'
					)"

					assert equal "${apache_load_modules}" "${apache_load_modules_details}"
				end
			end

			it "Logs to the default Apache access log path (/var/www/app/var/log/apache_access_log)."
				local apache_access_log_entry=""
				local curl_request_head=""

				curl_get_request="$(
					curl -s \
						--header 'Host: app-1.local' \
						http://127.0.0.1:${container_port_80}
				)"

				apache_access_log_entry="$(
					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/www/app/var/log/apache_access_log
				)"

				assert match "${apache_access_log_entry}" ""GET / HTTP/1.1" 200"

				it "Logs using the default LogFormat (combined)."
					local status_apache_access_log_pattern=""

					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/www/app/var/log/apache_access_log \
					| grep -qE \
						'^.+ .+ .+ \[.+\] "GET / HTTP/1\.1" 200 .+ ".+" ".*"$'

					status_apache_access_log_pattern=${?}

					assert equal "${status_apache_access_log_pattern}" 0
				end
			end

			it "Logs to the default Apache error log path (/var/www/app/var/log/apache_error_log)."
				local apache_error_log_entry=""
				local curl_request_head=""

				curl_get_request="$(
					curl -s \
						--header 'Host: app-1.local' \
						http://127.0.0.1:${container_port_80}
				)"

				apache_error_log_entry="$(
					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/www/app/var/log/apache_error_log
				)"

				assert equal "${apache_error_log_entry}" ""
			end
		end

		docker_terminate_container apache-php.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end
end
