#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${BACKUP_LOCAL:=/data/local}
echo ${BACKUP_REMOTE_PATH:=/SnapGizmos/Backups/}
source /data/scripts/functions.sh

STAMP=$(date +%Y%m%d%H%M)
SRC_PATH=$BACKUP_STOR/$SERVICE_NAME
BKP_EXT=sql.gz
env

eval $(oc env dc/$SERVICE_NAME --list | grep -v \\#)

if [ -z "$DESTINATION_PATH" ]; then
	echo "Missing mandatory parameter DESTINATION_PATH ";
	exit -1;
fi;

echo " ###### Checking service status .. "
wait_service $DBSERVICE_NAME
wait_service_pods $DBSERVICE_NAME

if [ ! -d $BACKUP_STOR/.gd ]; then
	echo "First time remote backup configuration"
	mkdir -p $BACKUP_STOR/.gd
	cp $BACKUP_SECRETS/.gd_credentials.json $BACKUP_STOR/.gd/credentials.json
fi;

find $SRC_PATH -type f
BACKUP_FILE=$(find $SRC_PATH -type f -printf '%Ts\t%p\n' | sort -nr | head -1 | awk '{{ print $2 }}')

echo " ###### Recovering from: $BACKUP_FILE to $DESTINATION_PATH " 
if [ -f "$BACKUP_FILE" ]; then
	echo tar -C $DESTINATION_PATH -xzf $BACKUP_FILE
	tar -C $DESTINATION_PATH -xzf $BACKUP_FILE
else
	echo "Backup no found under $DEST_PATH, let's recover from remote ! "
	cd $BACKUP_STOR
	gdrive ls
	gdrive pull -piped -force -destination $BACKUP_REMOTE_PATH $DBSERVICE_NAME.$BKP_EXT | gunzip 
fi;

