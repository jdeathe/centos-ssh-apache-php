#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]]; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]]; then
	cd ${DIR_PATH}
fi

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

OPT_SERVICE_NAME_FULL=${SERVICE_NAME_FULL:-apache-php.app-1.1.1@8080.service}
OPT_SERVICE_NAME_SHORT=$(cut -d '@' -f1 <<< "${OPT_SERVICE_NAME_FULL}")

# Stop the service and remove containers.
sudo systemctl stop ${OPT_SERVICE_NAME_FULL} &> /dev/null
remove_docker_container_name volume-config.${OPT_SERVICE_NAME_SHORT}
remove_docker_container_name ${OPT_SERVICE_NAME_SHORT}

# Copy systemd definition into place and enable it.
sudo cp ${OPT_SERVICE_NAME_FULL} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable /etc/systemd/system/${OPT_SERVICE_NAME_FULL}

echo "This may take a while if pulling large container images."
sudo systemctl restart ${OPT_SERVICE_NAME_FULL} &

# If we have the timeout command then use it, otherwise wait for use to cancel
TIMEOUT=
if type "timeout" &> /dev/null; then
	TIMEOUT="timeout 30 "
fi

# Tail the systemd unit logs to check progress.
${TIMEOUT}journalctl -fu ${OPT_SERVICE_NAME_FULL}

# Final service status report.
sudo systemctl status -l ${OPT_SERVICE_NAME_FULL}
