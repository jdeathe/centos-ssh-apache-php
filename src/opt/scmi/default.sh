
# Handle incrementing the docker host port for instances unless a port range is defined.
DOCKER_PUBLISH=
if [[ ${DOCKER_PORT_MAP_TCP_80} != NULL ]]; then
	if grep -qE '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[0-9]*$' <<< "${DOCKER_PORT_MAP_TCP_80}" \
		&& grep -qE '^.+\.([0-9]+)\.([0-9]+)$' <<< "${DOCKER_NAME}"; then
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s%s:80' \
			"${DOCKER_PUBLISH}" \
			"$(grep -o '^[0-9\.]*:' <<< "${DOCKER_PORT_MAP_TCP_80}")" \
			"$(( $(grep -o '[0-9]*$' <<< "${DOCKER_PORT_MAP_TCP_80}") + $(sed 's~\.[0-9]*$~~' <<< "${DOCKER_NAME}" | awk -F. '{ print $NF; }') - 1 ))"
	else
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s:80' \
			"${DOCKER_PUBLISH}" \
			"${DOCKER_PORT_MAP_TCP_80}"
	fi
fi

if [[ ${DOCKER_PORT_MAP_TCP_443} != NULL ]] \
	&& [[ ${APACHE_MOD_SSL_ENABLED} == true ]]; then
	if grep -qE '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[0-9]*$' <<< "${DOCKER_PORT_MAP_TCP_443}" \
		&& grep -qE '^.+\.([0-9]+)\.([0-9]+)$' <<< "${DOCKER_NAME}"; then
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s%s:443' \
			"${DOCKER_PUBLISH}" \
			"$(grep -o '^[0-9\.]*:' <<< "${DOCKER_PORT_MAP_TCP_443}")" \
			"$(( $(grep -o '[0-9]*$' <<< "${DOCKER_PORT_MAP_TCP_443}") + $(sed 's~\.[0-9]*$~~' <<< "${DOCKER_NAME}" | awk -F. '{ print $NF; }') - 1 ))"
	else
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s:443' \
			"${DOCKER_PUBLISH}" \
			"${DOCKER_PORT_MAP_TCP_443}"
	fi
fi

if [[ ${DOCKER_PORT_MAP_TCP_8443} != NULL ]]; then
	if grep -qE '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[0-9]*$' <<< "${DOCKER_PORT_MAP_TCP_8443}" \
		&& grep -qE '^.+\.([0-9]+)\.([0-9]+)$' <<< "${DOCKER_NAME}"; then
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s%s:8443' \
			"${DOCKER_PUBLISH}" \
			"$(grep -o '^[0-9\.]*:' <<< "${DOCKER_PORT_MAP_TCP_8443}")" \
			"$(( $(grep -o '[0-9]*$' <<< "${DOCKER_PORT_MAP_TCP_8443}") + $(sed 's~\.[0-9]*$~~' <<< "${DOCKER_NAME}" | awk -F. '{ print $NF; }') - 1 ))"
	else
		printf -v \
			DOCKER_PUBLISH \
			-- '%s --publish %s:8443' \
			"${DOCKER_PUBLISH}" \
			"${DOCKER_PORT_MAP_TCP_8443}"
	fi
fi

# Common parameters of create and run targets
DOCKER_CONTAINER_PARAMETERS="--name ${DOCKER_NAME} \
--restart ${DOCKER_RESTART_POLICY} \
--env \"APACHE_CONTENT_ROOT=${APACHE_CONTENT_ROOT}\" \
--env \"APACHE_CUSTOM_LOG_FORMAT=${APACHE_CUSTOM_LOG_FORMAT}\" \
--env \"APACHE_CUSTOM_LOG_LOCATION=${APACHE_CUSTOM_LOG_LOCATION}\" \
--env \"APACHE_ERROR_LOG_LOCATION=${APACHE_ERROR_LOG_LOCATION}\" \
--env \"APACHE_ERROR_LOG_LEVEL=${APACHE_ERROR_LOG_LEVEL}\" \
--env \"APACHE_EXTENDED_STATUS_ENABLED=${APACHE_EXTENDED_STATUS_ENABLED}\" \
--env \"APACHE_HEADER_X_SERVICE_UID=${APACHE_HEADER_X_SERVICE_UID}\" \
--env \"APACHE_LOAD_MODULES=${APACHE_LOAD_MODULES}\" \
--env \"APACHE_MOD_SSL_ENABLED=${APACHE_MOD_SSL_ENABLED}\" \
--env \"APACHE_MPM=${APACHE_MPM}\" \
--env \"APACHE_OPERATING_MODE=${APACHE_OPERATING_MODE}\" \
--env \"APACHE_PUBLIC_DIRECTORY=${APACHE_PUBLIC_DIRECTORY}\" \
--env \"APACHE_RUN_GROUP=${APACHE_RUN_GROUP}\" \
--env \"APACHE_RUN_USER=${APACHE_RUN_USER}\" \
--env \"APACHE_SERVER_ALIAS=${APACHE_SERVER_ALIAS}\" \
--env \"APACHE_SERVER_NAME=${APACHE_SERVER_NAME}\" \
--env \"APACHE_SSL_CERTIFICATE=${APACHE_SSL_CERTIFICATE}\" \
--env \"APACHE_SSL_CIPHER_SUITE=${APACHE_SSL_CIPHER_SUITE}\" \
--env \"APACHE_SSL_PROTOCOL=${APACHE_SSL_PROTOCOL}\" \
--env \"APACHE_SYSTEM_USER=${APACHE_SYSTEM_USER}\" \
--env \"PHP_OPTIONS_DATE_TIMEZONE=${PHP_OPTIONS_DATE_TIMEZONE}\" \
${DOCKER_PUBLISH}"
