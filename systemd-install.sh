#!/usr/bin/env bash

DIR_PATH="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ $DIR_PATH == */* ]] && [[ $DIR_PATH != "$( pwd )" ]] ; then
	cd $DIR_PATH
fi

have_docker_container_name ()
{
	local NAME=$1

	if [[ -n $(docker ps -a | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	else
		return 1
	fi
}

is_docker_container_name_running ()
{
	local NAME=$1

	if [[ -n $(docker ps | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	else
		return 1
	fi
}

remove_docker_container_name ()
{
	local NAME=$1

	if have_docker_container_name ${NAME} ; then
		if is_docker_container_name_running ${NAME} ; then
			echo Stopping container ${NAME}
			(docker stop ${NAME})
		fi
		echo Removing container ${NAME}
		(docker rm ${NAME})
	fi
}

loading_counter ()
{
	local COUNTER=${1:-10}

	while [ ${COUNTER} -ge 1 ]; do
		echo -ne "Loading in: ${COUNTER} \r"
		sleep 1
		COUNTER=$[${COUNTER}-1]
	done
}

OPT_SERVICE_NAME_FULL=${SERVICE_NAME_FULL:-apache-php.app-1.1.1@8080.service}
OPT_SERVICE_NAME_SHORT=$(cut -d '@' -f1 <<< "${OPT_SERVICE_NAME_FULL}")

# Add required configuration directories
mkdir -p /etc/services-config/${OPT_SERVICE_NAME_SHORT}/{httpd,supervisor,ssl/{certs,private}}

if [[ ! -n $(find /etc/services-config/${OPT_SERVICE_NAME_SHORT}/supervisor -maxdepth 1 -type f) ]]; then
	cp -R etc/services-config/supervisor /etc/services-config/${OPT_SERVICE_NAME_SHORT}/
fi

if [[ ! -n $(find /etc/services-config/${OPT_SERVICE_NAME_SHORT}/mysql -maxdepth 1 -type f) ]]; then
	cp -R etc/services-config/httpd /etc/services-config/${OPT_SERVICE_NAME_SHORT}/
fi

# Force 
sudo systemctl stop ${OPT_SERVICE_NAME_FULL} &> /dev/null
remove_docker_container_name volume-config.${OPT_SERVICE_NAME_SHORT}
remove_docker_container_name ${OPT_SERVICE_NAME_SHORT}

sudo cp ${OPT_SERVICE_NAME_FULL} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable /etc/systemd/system/${OPT_SERVICE_NAME_FULL}

echo "WARNING: This may take a while if pulling large container images for the first time..."
sudo systemctl restart ${OPT_SERVICE_NAME_FULL}

loading_counter 5

docker logs ${OPT_SERVICE_NAME_SHORT}