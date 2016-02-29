#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]]; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]]; then
	cd ${DIR_PATH}
fi

source run.conf

have_docker_container_name ()
{
	local NAME=$1

	if [[ -z ${NAME} ]]; then
		return 1
	fi

	if [[ -n $(docker ps -a | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	fi

	return 1
}

is_docker_container_name_running ()
{
	local NAME=$1

	if [[ -z ${NAME} ]]; then
		return 1
	fi

	if [[ -n $(docker ps | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	fi

	return 1
}

remove_docker_container_name ()
{
	local NAME=$1

	if have_docker_container_name ${NAME}; then
		if is_docker_container_name_running ${NAME}; then
			echo "Stopping container ${NAME}"
			(docker stop ${NAME})
		fi
		echo "Removing container ${NAME}"
		(docker rm ${NAME})
	fi
}

# Configuration volume
if [[ ${VOLUME_CONFIG_ENABLED} == true ]] && ! have_docker_container_name ${VOLUME_CONFIG_NAME}; then
	echo "Creating configuration volume container."

	if [[ ${VOLUME_CONFIG_NAMED} == true ]]; then
		DOCKER_VOLUME_MAPPING=${VOLUME_CONFIG_NAME}:/etc/services-config
	else
		DOCKER_VOLUME_MAPPING=/etc/services-config
	fi

	(
	set -x
	docker run \
		--name ${VOLUME_CONFIG_NAME} \
		-v ${DOCKER_VOLUME_MAPPING} \
		${DOCKER_IMAGE_REPOSITORY_NAME} \
		/bin/true;
	)

	# Named data volumes require files to be copied into place.
	if [[ ${VOLUME_CONFIG_NAMED} == true ]]; then
		echo "Populating configuration volume."
		(
		set -x
		docker cp \
			./etc/services-config/. \
			${DOCKER_VOLUME_MAPPING};
		)
	fi
fi

APACHE_SERVER_HOME=$(dirname "${APACHE_CONTENT_ROOT}")

# Data volume mapping
if [[ ${VOLUME_DATA_NAMED} == true ]]; then
	DOCKER_DATA_VOLUME_MAPPING=${VOLUME_DATA_NAME}:${APACHE_SERVER_HOME}
else
	DOCKER_DATA_VOLUME_MAPPING=${APACHE_SERVER_HOME}
fi

# Data volume container
if [[ ${VOLUME_DATA_ENABLED} == true ]] && ! have_docker_container_name ${VOLUME_DATA_NAME}; then
	echo "Creating data volume container."

	(
	set -x
	docker run \
		--name ${VOLUME_DATA_NAME} \
		-v ${DOCKER_DATA_VOLUME_MAPPING} \
		${DOCKER_IMAGE_REPOSITORY_NAME} \
		/bin/true;
	)
fi

# Application container
remove_docker_container_name ${DOCKER_NAME}

if [[ ${#} -eq 0 ]]; then
	echo "Running container ${DOCKER_NAME} as a background/daemon process."
	DOCKER_OPERATOR_OPTIONS="-d"
else
	# This is useful for running commands like 'export' or 'env' to check the 
	# environment variables set by the --link docker option.
	# 
	# If you need to pipe to another command, quote the commands. e.g: 
	#   ./run.sh "env | grep APACHE | sort"
	printf "Running container %s with CMD [/bin/bash -c '%s']\n" "${DOCKER_NAME}" "${*}"
	DOCKER_OPERATOR_OPTIONS="-it --entrypoint /bin/bash --env TERM=${TERM:-xterm}"
fi

# Enable/Disable SSL support
if [[ ${APACHE_MOD_SSL_ENABLED} == true ]]; then
	DOCKER_PORT_OPTIONS="-p ${DOCKER_HOST_PORT_HTTP:-}:80 -p ${DOCKER_HOST_PORT_HTTPS:-}:443"
else
	DOCKER_PORT_OPTIONS="-p ${DOCKER_HOST_PORT_HTTP:-}:80 -p ${DOCKER_HOST_PORT_HTTPS:-}:8443"
fi

DOCKER_VOLUMES_FROM=
if [[ ${VOLUME_CONFIG_ENABLED} == true ]] && have_docker_container_name ${VOLUME_CONFIG_NAME}; then
	DOCKER_VOLUMES_FROM="--volumes-from ${VOLUME_CONFIG_NAME}"
fi

if [[ ${VOLUME_DATA_ENABLED} == true ]] && have_docker_container_name ${VOLUME_DATA_NAME}; then
	DOCKER_VOLUMES_FROM+="${DOCKER_VOLUMES_FROM:+ }--volumes-from ${VOLUME_DATA_NAME}"
else
	DOCKER_VOLUMES_FROM+="${DOCKER_VOLUMES_FROM:+ }-v ${DOCKER_DATA_VOLUME_MAPPING}"
fi

# In a sub-shell set xtrace - prints the docker command to screen for reference
(
set -x
docker run \
	${DOCKER_OPERATOR_OPTIONS} \
	--name "${DOCKER_NAME}" \
	${DOCKER_PORT_OPTIONS} \
	--env "SERVICE_UNIT_APP_GROUP=${SERVICE_UNIT_APP_GROUP}" \
	--env "SERVICE_UNIT_LOCAL_ID=${SERVICE_UNIT_LOCAL_ID}" \
	--env "SERVICE_UNIT_INSTANCE=${SERVICE_UNIT_INSTANCE}" \
	--env "APACHE_CONTENT_ROOT=${APACHE_CONTENT_ROOT}" \
	--env "APACHE_EXTENDED_STATUS_ENABLED=${APACHE_EXTENDED_STATUS_ENABLED}" \
	--env "APACHE_LOAD_MODULES=${APACHE_LOAD_MODULES}" \
	--env "APACHE_MOD_SSL_ENABLED=${APACHE_MOD_SSL_ENABLED}" \
 	--env "APACHE_RUN_GROUP=${APACHE_RUN_GROUP}" \
 	--env "APACHE_RUN_USER=${APACHE_RUN_USER}" \
	--env "APACHE_SERVER_ALIAS=${APACHE_SERVER_ALIAS}" \
	--env "APACHE_SERVER_NAME=${APACHE_SERVER_NAME}" \
	--env "DATE_TIMEZONE=${DATE_TIMEZONE}" \
	--env "HTTPD=${HTTPD}" \
	--env "SERVICE_USER=${SERVICE_USER}" \
	--env "SUEXECUSERGROUP=${SUEXECUSERGROUP}" \
	${DOCKER_VOLUMES_FROM:-} \
	${DOCKER_IMAGE_REPOSITORY_NAME}${@:+ -c }"${@}"
)

# Linked MySQL + SSH + XDebug remote debugging port + Apache rewrite module
# (
# set -x
# docker run \
# 	${DOCKER_OPERATOR_OPTIONS} \
# 	--name "${DOCKER_NAME}" \
# 	${DOCKER_PORT_OPTIONS} \
# 	-p ${DOCKER_HOST_PORT_SSH:-}:22 \
# 	-p ${DOCKER_HOST_PORT_XDEBUG:-}:9000 \
# 	--link ${DOCKER_LINK_NAME_DB_MYSQL}:${DOCKER_LINK_ID_DB_MYSQL} \
# 	--env "SERVICE_UNIT_APP_GROUP=app-1" \
# 	--env "SERVICE_UNIT_LOCAL_ID=1" \
# 	--env "SERVICE_UNIT_INSTANCE=1" \
# 	--env "APACHE_CONTENT_ROOT=/var/www/app-1" \
# 	--env "APACHE_EXTENDED_STATUS_ENABLED=true"
# 	--env "APACHE_LOAD_MODULES=${APACHE_LOAD_MODULES} rewrite_module" \
# 	--env "APACHE_MOD_SSL_ENABLED=false" \
# 	--env "APACHE_RUN_GROUP=www-app" \
# 	--env "APACHE_RUN_USER=www-app" \
# 	--env "APACHE_SERVER_ALIAS=app-1 www.app-1 www.app-1.local" \
# 	--env "APACHE_SERVER_NAME=app-1.local" \
# 	--env "DATE_TIMEZONE=Europe/London" \
# 	--env "HTTPD=/usr/sbin/httpd.worker" \
# 	--env "SERVICE_USER=app" \
# 	--env "SUEXECUSERGROUP=false" \
# 	${DOCKER_VOLUMES_FROM:-} \
# 	${DOCKER_IMAGE_REPOSITORY_NAME}${@:+ -c }"${@}"
# )

if is_docker_container_name_running ${DOCKER_NAME}; then
	docker ps | awk -v pattern="${DOCKER_NAME}$" '$NF ~ pattern { print $0; }'
	echo " ---> Docker container running."
fi
