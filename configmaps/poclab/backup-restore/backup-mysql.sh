#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${BACKUP_LOCAL:=/data/local}
echo ${BACKUP_REMOTE_PATH:=/SnapGizmos/Backups/}
source /data/scripts/functions.sh

echo " ###### Loading $SERVICE_NAME Environment "
eval $(oc env dc/$SERVICE_NAME --list | grep -v \\#)
STAMP=$(date +%Y%m%d%H%M)
DEST_PATH=$BACKUP_STOR/$DBSERVICE_NAME/$STAMP
BKP_EXT=sql.gz
env

if [ -d $BACKUP_STOR/.gd ]; then
	echo " ###### creating backups folder"
	mkdir -p $BACKUP_STOR/.gd
	cp $BACKUP_SECRETS/.gd_credentials.json $BACKUP_STOR/.gd/credentials.json
fi;

echo " ###### Checking service status .. "
wait_service $DBSERVICE_NAME

echo " ###### Running backup "
if [ ! -z $DEST_PATH ]; then
	echo "Creating folder $DEST_PATH "
	mkdir -p $DEST_PATH;
fi;

mysqldump -h $MYSQL_SERVICE_HOST -u root --password=$MYSQL_PASSWORD --all-databases | gzip -9 -c > $DEST_PATH/$DBSERVICE_NAME-$STAMP.$BKP_EXT

echo "Backed up file: "
ls -al $DEST_PATH/$DBSERVICE_NAME-$STAMP.$BKP_EXT

#echo " ###### let's give it a shot! "
#cd $BACKUP_STOR
#zcat $DEST_PATH/$DBSERVICE_NAME-$STAMP.sql.gz | gdrive push -piped -force -destination $BACKUP_REMOTE_PATH $DBSERVICE_NAME.$BKP_EXT


