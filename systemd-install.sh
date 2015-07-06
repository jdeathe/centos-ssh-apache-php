#!/usr/bin/env bash

DIR_PATH="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ $DIR_PATH == */* ]] && [[ $DIR_PATH != "$( pwd )" ]] ; then
	cd $DIR_PATH
fi

OPT_SERVICE_NAME_FULL=${SERVICE_NAME_FULL:-apache-php.app-1.1.1@8080.service}
OPT_SERVICE_NAME_SHORT=$(cut -d '@' -f1 <<< "${OPT_SERVICE_NAME_FULL}")

# Force 
systemctl stop ${OPT_SERVICE_NAME_FULL}
docker rm volume-config.${OPT_SERVICE_NAME_SHORT} && \
docker rm ${OPT_SERVICE_NAME_SHORT}

cp ${OPT_SERVICE_NAME_FULL} /etc/systemd/system/
systemctl daemon-reload
systemctl enable /etc/systemd/system/${OPT_SERVICE_NAME_FULL}

echo "WARNING: This may take a while if pulling large container images for the first time..."
systemctl restart ${OPT_SERVICE_NAME_FULL}

sleep 10

docker logs ${OPT_SERVICE_NAME_SHORT}