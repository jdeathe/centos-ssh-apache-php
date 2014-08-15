#!/usr/bin/env bash

DIR_PATH="$( cd "$( echo "${0%/*}" )"; pwd )"
if [[ $DIR_PATH == */* ]]; then
	cd $DIR_PATH
fi

source run.conf

OPTS_APACHE_MOD_SSL_ENABLED="${APACHE_MOD_SSL_ENABLED:-false}"

# Enable/Disable SSL support
if [[ ${OPTS_APACHE_MOD_SSL_ENABLED} == "true" ]]; then
	OPTS_HTTPS_PORT=443
else
	OPTS_HTTPS_PORT=8443
fi

have_docker_container_name ()
{
	NAME=$1

	if [[ -n $(docker ps -a | grep -v -e "${NAME}/.*,.*" | grep -o ${NAME}) ]]; then
		return 0
	else
		return 1
	fi
}

is_docker_container_name_running ()
{
	NAME=$1

	if [[ -n $(docker ps | grep -v -e "${NAME}/.*,.*" | grep -o ${NAME}) ]]; then
		return 0
	else
		return 1
	fi
}

remove_docker_container_name ()
{
	NAME=$1

	if have_docker_container_name ${NAME} ; then
		if is_docker_container_name_running ${NAME} ; then
			echo Stopping container ${NAME}...
			(docker stop ${NAME})
		fi
		echo Removing container ${NAME}...
		(docker rm ${NAME})
	fi
}

# Configuration volume
if [ ! "${VOLUME_CONFIG_NAME}" == "$(docker ps -a | grep -v -e \"${VOLUME_CONFIG_NAME}/.*,.*\" | grep -e '[ ]\{1,\}'${VOLUME_CONFIG_NAME} | grep -o ${VOLUME_CONFIG_NAME})" ]; then
(
set -x
docker run \
	--name ${VOLUME_CONFIG_NAME} \
	-v ${MOUNT_PATH_CONFIG}/ssh.${SERVICE_UNIT_SHARED_GROUP}:/etc/services-config/ssh \
	-v ${MOUNT_PATH_CONFIG}/${DOCKER_NAME}/supervisor:/etc/services-config/supervisor \
	-v ${MOUNT_PATH_CONFIG}/${DOCKER_NAME}/httpd:/etc/services-config/httpd \
	-v ${MOUNT_PATH_CONFIG}/${DOCKER_NAME}/ssl/certs:/etc/services-config/ssl/certs \
	-v ${MOUNT_PATH_CONFIG}/${DOCKER_NAME}/ssl/private:/etc/services-config/ssl/private \
	busybox:latest \
	/bin/true;
)
fi

# Force replace container of same name if found to exist
remove_docker_container_name ${DOCKER_NAME}

if [ -z ${1+x} ]; then
	echo Running container ${NAME} as a background/daemon process...
	DOCKER_OPERATOR_OPTIONS="-d --entrypoint /bin/bash"
	DOCKER_COMMAND="/usr/bin/supervisord --configuration=/etc/supervisord.conf"
else
	# This is usful for running commands like 'export' or 'env' to check the environment variables set by the --link docker option
	echo Running container ${NAME} with command: /bin/bash -c \'"$@"\'...
	DOCKER_OPERATOR_OPTIONS="--entrypoint /bin/bash"
	DOCKER_COMMAND=${@}
fi

# In a sub-shell set xtrace - prints the docker command to screen for reference
(
set -x
docker run \
	${DOCKER_OPERATOR_OPTIONS} \
	--name "${DOCKER_NAME}" \
	-p 8080:80 \
	-p 8580:${OPTS_HTTPS_PORT} \
	--env SERVICE_UNIT_APP_GROUP=${SERVICE_UNIT_APP_GROUP} \
	--env SERVICE_UNIT_LOCAL_ID=${SERVICE_UNIT_LOCAL_ID} \
	--env SERVICE_UNIT_INSTANCE=${SERVICE_UNIT_INSTANCE} \
	--env APACHE_SERVER_NAME=${SERVICE_UNIT_APP_GROUP}.local \
	--env APACHE_SERVER_ALIAS=${SERVICE_UNIT_APP_GROUP} \
	--env DATE_TIMEZONE=${DATE_TIMEZONE} \
	--volumes-from ${VOLUME_CONFIG_NAME} \
	-v ${MOUNT_PATH_DATA}/${SERVICE_UNIT_NAME}/${SERVICE_UNIT_APP_GROUP}:/var/www/app \
	${DOCKER_IMAGE_REPOSITORY_NAME} -c "${DOCKER_COMMAND}"
)

# Linked MySQL + SSH + XDebug remote debugging port
# (
# set -x
# docker run \
# 	${DOCKER_OPERATOR_OPTIONS} \
# 	--name "${DOCKER_NAME}" \
# 	-p 8080:80 \
# 	-p 8580:${OPTS_HTTPS_PORT} \
# 	-p 2312:22 \
# 	-p :9000 \
# 	--link ${DOCKER_NAME_DB_MYSQL}:db_mysql \
# 	--env SERVICE_UNIT_APP_GROUP=${SERVICE_UNIT_APP_GROUP} \
# 	--env SERVICE_UNIT_LOCAL_ID=${SERVICE_UNIT_LOCAL_ID} \
# 	--env SERVICE_UNIT_INSTANCE=${SERVICE_UNIT_INSTANCE} \
# 	--env APACHE_SERVER_NAME=${SERVICE_UNIT_APP_GROUP}.local \
# 	--env APACHE_SERVER_ALIAS=${SERVICE_UNIT_APP_GROUP} \
# 	--volumes-from ${VOLUME_CONFIG_NAME} \
# 	-v ${MOUNT_PATH_DATA}/${SERVICE_UNIT_NAME}/${SERVICE_UNIT_APP_GROUP}:/var/www/app \
# 	${DOCKER_IMAGE_REPOSITORY_NAME} -c "${DOCKER_COMMAND}"
# )

if is_docker_container_name_running ${DOCKER_NAME} ; then
	docker ps | grep -v -e "${DOCKER_NAME}/.*,.*" | grep ${DOCKER_NAME}
	echo " ---> Docker container running."
fi
