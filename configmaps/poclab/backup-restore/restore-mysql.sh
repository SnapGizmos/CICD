#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${BACKUP_REMOTE_PATH:=SnapGizmos/Backups/}
echo ${BACKUP_NAMESPACE:=$(oc describe pod $HOSTNAME|grep ^Namespace|awk -F ':' '{{print $2}}'|tr -d '[:space:]')}
echo ${SERVICE_NAME=mysql}
source /data/scripts/functions.sh

STAMP=$(date +%Y%m%d%H%M)
DEST_PATH=$BACKUP_STOR/$SERVICE_NAME
BKP_EXT=sql.gz
env

eval $(oc env dc/$SERVICE_NAME --list | grep -v \\#)

echo " ###### Checking service status .. "
wait_service $SERVICE_NAME

if [ ! -d $BACKUP_STOR/.gd ]; then
	echo "First time remote backup configuration"
	mkdir -p $BACKUP_STOR/.gd
	cp $BACKUP_SECRETS/.gd_credentials.json $BACKUP_STOR/.gd/credentials.json
fi;

echo " ###### Recovering from: $BACKUP_FILE " 
find $DEST_PATH -type f
BACKUP_FILE=$(find $DEST_PATH -type f -printf '%Ts\t%p\n' | sort -nr | head -1 | awk '{{ print $2 }}')

if [ ! -f "$BACKUP_FILE" ]; then
	echo "Backup no found under $DEST_PATH, let's recover from remote ! "
	cd $BACKUP_STOR
	gdrive list $BACKUP_REMOTE_PATH
	gdrive pull -ignore-checksum=false -no-prompt -verbose -piped $BACKUP_REMOTE_PATH/$BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT | gunzip | mysql -h $MYSQL_SERVICE_HOST -u root --password=$MYSQL_PASSWORD 
fi;

if [ -f "$BACKUP_FILE" ]; then
	gunzip -c $BACKUP_FILE | mysql -h $MYSQL_SERVICE_HOST -u root --password=$MYSQL_PASSWORD 
fi;

echo " ########################################## "
echo " ############ END of Script ############### "
