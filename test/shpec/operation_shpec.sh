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
		end

		docker_terminate_container apache-php.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end
end
