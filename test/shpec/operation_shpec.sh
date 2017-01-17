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
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

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

				it "Includes the header X-Service-UID default ({{HOSTNAME}} replacement)."
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
				local curl_get_request=""

				curl_get_request="$(
					curl -s \
						--header 'Host: app-1.local' \
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

				assert equal "${apache_access_log_entry}" "\"GET / HTTP/1.1\" 200"

				it "Logs using the default LogFormat (combined)."
					local status_apache_access_log_pattern=""

					docker exec \
						apache-php.pool-1.1.1 \
						tail -n 1 \
						/var/www/app/var/log/apache_access_log \
					| grep -qE \
						'^.+ .+ .+ \[.+\] "GET / HTTP/1\.1" 200 .+ ".+" ".*"$' \
					&> /dev/null

					status_apache_access_log_pattern=${?}

					assert equal "${status_apache_access_log_pattern}" 0
				end
			end

			it "Logs to the default Apache error log path (/var/www/app/var/log/apache_error_log)."
				local status_apache_error_log_path=""
				local curl_get_request=""

				curl_get_request="$(
					curl -s \
						--header 'Host: app-1.local' \
						http://127.0.0.1:${container_port_80}
				)"

				docker exec \
					apache-php.pool-1.1.1 \
					tail -n 1 \
					/var/www/app/var/log/apache_error_log \
				&> /dev/null

				status_apache_error_log_path=${?}

				assert equal "${status_apache_error_log_path}" 0
			end

			it "Apache server-status can be accessed from localhost."
				local status_apache_server_status_pattern=""

				docker exec \
					apache-php.pool-1.1.1 \
					curl -s \
						http://app-1.local/server-status\?auto \
				| grep -qE \
					'^ServerVersion: Apache/2\.[3-4]\.[0-9]+ \(CentOS\)' \
				&> /dev/null

				status_apache_server_status_pattern=${?}

				assert equal "${status_apache_server_status_pattern}" 0

				it "Excludes information available with ExtendedStatus enabled."
					local status_apache_server_status_pattern=""

					docker exec \
						apache-php.pool-1.1.1 \
						curl -s \
							http://app-1.local/server-status\?auto \
					| grep -qE \
						'^Total Accesses: [0-9]+' \
					&> /dev/null

					status_apache_server_status_pattern=${?}

					# TODO - ISSUE 291: ExtendedStatus should be off by default.
					# assert equal "${status_apache_server_status_pattern}" 1
				end

				it "Prevents remote access to server-status."
					local status_apache_server_status_pattern=""
					local curl_get_request=""

					curl -s \
						--header 'Host: app-1.local' \
						http://127.0.0.1:${container_port_80}/server-status\?auto \
					| grep -qE \
						'^ServerVersion: Apache/2\.[3-4]\.[0-9]+ \(CentOS\)' \
					&> /dev/null

					status_apache_server_status_pattern=${?}

					assert equal "${status_apache_server_status_pattern}" 1

					it "Responds with a 403 status code."
						local curl_response_code=""

						curl_response_code="$(
							curl -s \
								-o /dev/null \
								-w "%{http_code}" \
								--header 'Host: app-1.local' \
								http://127.0.0.1:${container_port_80}/server-status\?auto
						)"

						assert equal "${curl_response_code}" "403"
					end
				end
			end

			it "Loads all the required Apache modules."
				readonly required_apache_modules="authz_core_module authz_user_module log_config_module expires_module deflate_module filter_module headers_module setenvif_module socache_shmcb_module mime_module status_module dir_module alias_module unixd_module version_module proxy_module proxy_fcgi_module"
				readonly other_required_apache_modules="core_module so_module http_module authz_host_module mpm_prefork_module ssl_module cgi_module"
				local status_apache_modules_loaded=0

				for module in ${required_apache_modules}; do
					docker exec \
						apache-php.pool-1.1.1 \
						bash -c "apachectl -M | grep -q ${module}"

					status_apache_modules_loaded=$((
						status_apache_modules_loaded + ${?}
					))
				done

				assert equal "${status_apache_modules_loaded}" 0

				it "Loads only the required Apache modules."
					local all_required_apache_modules="${required_apache_modules} ${other_required_apache_modules}"
					local all_loaded_apache_modules=""
					local status_minimal_apache_modules_loaded=""

					all_loaded_apache_modules="$(
						docker exec \
							apache-php.pool-1.1.1 \
							bash -c "apachectl -M | sed -e '/Loaded Modules:/d' -e 's~^ *\([a-z_]*\).*~\1~g'"
					)"

					for module in ${all_loaded_apache_modules}; do
						if [[ ! "${all_required_apache_modules}" =~ "${module}" ]]; then
							status_minimal_apache_modules_loaded=1
							break
						fi
					done

					assert unequal "${status_minimal_apache_modules_loaded}" 1
				end
			end

			it "Runs Apache using the default user:group (app-www:app-www)."
				local apache_run_user_group=""

				apache_run_user_group="$(
					docker exec \
						apache-php.pool-1.1.1 \
						ps axo user,group,comm \
					| grep httpd \
					| tail -n 1 \
					| awk '{ print $1":"$2 }'
				)"

				assert equal "${apache_run_user_group}" "app-www:app-www"
			end
		end

		docker_terminate_container apache-php.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end

	describe "Customised Apache PHP configuration"
		trap "docker_terminate_container apache-php.pool-1.1.1 &> /dev/null" \
			INT TERM EXIT

		it "Allows configuration with Apache common LogFormat."
			local curl_get_request=""
			local status_apache_access_log_pattern=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_CUSTOM_LOG_FORMAT="common" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl_get_request="$(
				curl -s \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80}
			)"

			docker exec \
				apache-php.pool-1.1.1 \
				tail -n 1 \
				/var/www/app/var/log/apache_access_log \
			| grep -qE \
				'^.+ .+ .+ \[.+\] "GET / HTTP/1\.1" 200 .+$' \
			&> /dev/null

			status_apache_access_log_pattern=${?}

			assert equal "${status_apache_access_log_pattern}" 0
		end

		it "Allows configuration with an alternative, relative, access log path."
			local apache_access_log_entry=""
			local curl_get_request=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_CUSTOM_LOG_LOCATION="var/log/access.log" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl_get_request="$(
				curl -s \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80}
			)"

			apache_access_log_entry="$(
				docker exec \
					apache-php.pool-1.1.1 \
					tail -n 1 \
					/var/www/app/var/log/access.log \
				| grep -oE \
					'"GET / HTTP/1\.1" 200' \
			)"

			assert equal "${apache_access_log_entry}" "\"GET / HTTP/1.1\" 200"
		end

		it "Allows configuration with an alternative, absolute, access log path."
			local apache_access_log_entry=""
			local curl_get_request=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_CUSTOM_LOG_LOCATION="/var/log/httpd/access.log" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl_get_request="$(
				curl -s \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80}
			)"

			apache_access_log_entry="$(
				docker exec \
					apache-php.pool-1.1.1 \
					tail -n 1 \
					/var/log/httpd/access.log \
				| grep -oE \
					'"GET / HTTP/1\.1" 200' \
			)"

			assert equal "${apache_access_log_entry}" "\"GET / HTTP/1.1\" 200"
		end

		it "Allows configuration with an alternative, relative, error log path."
			local curl_get_request=""
			local status_apache_error_log_path=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_ERROR_LOG_LOCATION="var/log/error.log" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl_get_request="$(
				curl -s \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80}
			)"

			docker exec \
				apache-php.pool-1.1.1 \
				tail -n 1 \
				/var/www/app/var/log/error.log \
			&> /dev/null

			status_apache_error_log_path=${?}

			assert equal "${status_apache_error_log_path}" 0
		end

		it "Allows configuration with an alternative, absolute, error log path."
			local curl_get_request=""
			local status_apache_error_log_path=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_ERROR_LOG_LOCATION="/var/log/httpd/error.log" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl_get_request="$(
				curl -s \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80}
			)"

			docker exec \
				apache-php.pool-1.1.1 \
				tail -n 1 \
				/var/log/httpd/error.log \
			&> /dev/null

			status_apache_error_log_path=${?}

			assert equal "${status_apache_error_log_path}" 0
		end

		it "Allows configuration with an alternative log level."
			local curl_get_request=""
			local status_apache_error_log_pattern=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_ERROR_LOG_LEVEL="debug" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl_get_request="$(
				curl -s \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80}
			)"

			docker exec \
				apache-php.pool-1.1.1 \
				tail -n 1 \
				/var/www/app/var/log/apache_error_log \
			| grep -qE \
				' \[.+:debug\] ' \
			&> /dev/null

			status_apache_error_log_pattern=${?}

			assert equal "${status_apache_error_log_pattern}" 0
		end

		it "Allows extended server-status to be enabled and accessed from localhost."
			local status_apache_server_status_pattern=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_EXTENDED_STATUS_ENABLED="true" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			docker exec \
				apache-php.pool-1.1.1 \
				curl -s \
					http://app-1.local/server-status\?auto \
			| grep -qE \
				'^Total Accesses: [0-9]+' \
			&> /dev/null

			status_apache_server_status_pattern=${?}

			assert equal "${status_apache_server_status_pattern}" 0

			it "Prevents remote access to server-status."
				local status_apache_server_status_pattern=""
				local curl_get_request=""

				curl -s \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80}/server-status\?auto \
				| grep -qE \
					'^Total Accesses: [0-9]+' \
				&> /dev/null

				status_apache_server_status_pattern=${?}

				assert equal "${status_apache_server_status_pattern}" 1

				it "Responds with a 403 status code."
					local curl_response_code=""

					curl_response_code="$(
						curl -s \
							-o /dev/null \
							-w "%{http_code}" \
							--header 'Host: app-1.local' \
							http://127.0.0.1:${container_port_80}/server-status\?auto
					)"

					assert equal "${curl_response_code}" "403"
				end
			end
		end

		it "Allows the header X-Service-UID to be set to a string value."
			local header_x_service_uid=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_HEADER_X_SERVICE_UID="host-name@1.2" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			header_x_service_uid="$(
				curl -sI \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80} \
				| grep '^X-Service-UID: ' \
				| cut -c 16- \
				| tr -d '\r'
			)"

			assert equal "${header_x_service_uid}" "host-name@1.2"

			it "Allows the {{HOSTNAME}} placeholder to be included in the value."
				local header_x_service_uid=""

				docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

				docker run -d \
					--name apache-php.pool-1.1.1 \
					--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
					--env APACHE_HEADER_X_SERVICE_UID="{{HOSTNAME}}:${DOCKER_PORT_MAP_TCP_80}" \
					--hostname app-1.local \
					jdeathe/centos-ssh-apache-php:latest \
				&> /dev/null

				sleep ${BOOTSTRAP_BACKOFF_TIME}

				header_x_service_uid="$(
					curl -sI \
						--header 'Host: app-1.local' \
						http://127.0.0.1:${container_port_80} \
					| grep '^X-Service-UID: ' \
					| cut -c 16- \
					| tr -d '\r'
				)"

				assert equal "${header_x_service_uid}" "app-1.local:${DOCKER_PORT_MAP_TCP_80}"
			end
		end

		it "Allows loading of additional Apache modules (e.g. rewrite_module)."
			local status_apache_module_loaded=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--env APACHE_LOAD_MODULES="authz_core_module authz_user_module log_config_module expires_module deflate_module filter_module headers_module setenvif_module socache_shmcb_module mime_module status_module dir_module alias_module unixd_module version_module proxy_module proxy_fcgi_module rewrite_module" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			docker exec \
				apache-php.pool-1.1.1 \
				bash -c "apachectl -M | grep -q rewrite_module"

			status_apache_module_loaded=${?}

			assert equal "${status_apache_module_loaded}" 0
		end

		it "Allows ssl_module to be enabled to accept encrypted requests (https)."
			local container_port_443=""
			local curl_response_code=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_443}:443 \
				--env APACHE_MOD_SSL_ENABLED="true" \
				--hostname app-1.local \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			container_port_443="$(
				docker port \
					apache-php.pool-1.1.1 \
					443/tcp
			)"
			container_port_443=${container_port_443##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl_response_code="$(
				curl -ks \
					-o /dev/null \
					-w "%{http_code}" \
					--header 'Host: app-1.local' \
					https://127.0.0.1:${container_port_443}
			)"

			assert equal "${curl_response_code}" "200"
		end

		it "Allows configuration of an alternative Apache MPM (event)."
			local status_apache_mpm_changed=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--env APACHE_MPM="event" \
				--hostname app-1.local \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			docker exec \
				apache-php.pool-1.1.1 \
				bash -c "apachectl -V | grep -qE '^Server MPM:[ ]+event$'"

			status_apache_mpm_changed=${?}

			assert equal "${status_apache_mpm_changed}" 0
		end

		it "Allows configuration of the Apache internal variable for operating mode."
			local header_x_service_operating_mode=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_OPERATING_MODE="development" \
				--hostname app-1.local \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			header_x_service_operating_mode="$(
				curl -sI \
					--header 'Host: app-1.local' \
					http://127.0.0.1:${container_port_80} \
				| grep '^X-Service-Operating-Mode: ' \
				| cut -c 27- \
				| tr -d '\r'
			)"

			assert equal "${header_x_service_operating_mode}" "development"
		end

		it "Allows configuration of the ServerName."
			local curl_response_code_default=""
			local curl_response_code_server_named=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_80}:80 \
				--env APACHE_SERVER_NAME="test.local" \
				--env APACHE_SERVER_ALIAS="www.test.local" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			# Add a default VirtualHost that rejects access (403 response).
			docker exec -i \
				apache-php.pool-1.1.1 \
				tee /etc/services-config/httpd/conf.d/05-vhost.conf 1> /dev/null <<-CONFIG
			Listen 8443
			<IfVersion < 2.4>
			    NameVirtualHost *:80
			    NameVirtualHost *:8443
			</IfVersion>

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

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			docker exec \
				apache-php.pool-1.1.1 \
				bash -c 'apachectl graceful'

			curl_response_code_default="$(
				curl -s \
					-o /dev/null \
					-w "%{http_code}" \
					http://127.0.0.1:${container_port_80}
			)"

			curl_response_code_server_named="$(
				curl -s \
					-o /dev/null \
					-w "%{http_code}" \
					--header 'Host: test.local' \
					http://127.0.0.1:${container_port_80}
			)"

			assert equal "${curl_response_code_default}:${curl_response_code_server_named}" "403:200"

			it "Allows configuration of a ServerAlias."
				local curl_response_code_server_alias=""

				curl_response_code_server_alias="$(
					curl -s \
						-o /dev/null \
						-w "%{http_code}" \
						--header 'Host: www.test.local' \
						http://127.0.0.1:${container_port_80}
				)"

				assert equal "${curl_response_code_server_alias}" "200"
			end
		end

		it "Allows configuration of the Apache public directory."
			local status_header_x_service_uid=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
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

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			curl -sI \
				--header 'Host: app-1.local' \
				http://127.0.0.1:${container_port_80} \
			| grep -q '^X-Service-UID: app-1.local' \
			&> /dev/null

			status_header_x_service_uid=${?}

			assert equal "${status_header_x_service_uid}" 0
		end

		it "Allows configuration of the user used to run Apache."
			local apache_run_user=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--env APACHE_RUN_USER="ausr" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			apache_run_user="$(
				docker exec \
					apache-php.pool-1.1.1 \
					ps axo user,group,comm \
				| grep httpd \
				| tail -n 1 \
				| awk '{ print $1 }'
			)"

			# TODO - ISSUE 293: Setting APACHE_RUN_GROUP ineffective.
			# assert equal "${apache_run_user}" "ausr"
		end

		it "Allows configuration of the group used to run Apache."
			local apache_run_group=""

			docker_terminate_container apache-php.pool-1.1.1 &> /dev/null

			docker run -d \
				--name apache-php.pool-1.1.1 \
				--env APACHE_RUN_GROUP="agrp" \
				jdeathe/centos-ssh-apache-php:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			apache_run_group="$(
				docker exec \
					apache-php.pool-1.1.1 \
					ps axo user,group,comm \
				| grep httpd \
				| tail -n 1 \
				| awk '{ print $2 }'
			)"

			# TODO - ISSUE 293: Setting APACHE_RUN_GROUP ineffective.
			# assert equal "${apache_run_group}" "agrp"
		end

		docker_terminate_container apache-php.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end
end
