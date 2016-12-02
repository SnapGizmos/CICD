#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${DBSERVICE_NAME:=mysql}
echo ${BACKUP_REMOTE_PATH:=/SnapGizmos/Backups/}
echo ${DBSERVICE_NAME=mysql}
source /data/scripts/functions.sh

STAMP=$(date +%Y%m%d%H%M)
DEST_PATH=$BACKUP_STOR/$DBSERVICE_NAME
BKP_EXT=sql.gz
env

eval $(oc env dc/$DBSERVICE_NAME --list | grep -v \\#)

echo " ###### Checking service status .. "
wait_service $DBSERVICE_NAME
wait_service_pods $DBSERVICE_NAME

find $DEST_PATH -type f
BACKUP_FILE=$(find $DEST_PATH -type f -printf '%Ts\t%p\n' | sort -nr | head -1 | awk '{{ print $2 }}')

echo " ###### Recovering from: $BACKUP_FILE " 
if [ ! -d $BACKUP_STOR/.gd ]; then
	echo "First time remote backup configuration"
	mkdir -p $BACKUP_STOR/.gd
	cp $BACKUP_SECRETS/.gd_credentials.json $BACKUP_STOR/.gd/credentials.json
fi;

if [ -f "$BACKUP_FILE" ]; then
	gunzip -c $BACKUP_FILE | mysql -h $MYSQL_SERVICE_HOST -u root --password=$MYSQL_PASSWORD 
else
	echo "Backup no found under $DEST_PATH, let's recover from remote ! "
	cd $BACKUP_STOR
	gdrive ls
	gdrive pull -piped -force -destination $BACKUP_REMOTE_PATH $DBSERVICE_NAME.$BKP_EXT | gunzip 
fi;

