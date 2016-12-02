#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${BACKUP_LOCAL:=/data/local}
echo ${BACKUP_REMOTE_PATH:=/SnapGizmos/Backups/}
source /data/scripts/functions.sh

if [ -z "$SERVICE_NAME" ]; then
	echo "Missing mandatory parameter SERVICE_NAME ";
	exit -1;
fi;

echo " ###### Loading $SERVICE_NAME Environment "
eval $(oc env dc/$SERVICE_NAME --list | grep -v \\#)
STAMP=$(date +%Y%m%d%H%M)
DEST_PATH=$BACKUP_STOR/$SERVICE_NAME/$STAMP
BKP_EXT=tgz
env

if [ -d $BACKUP_STOR/.gd ]; then
	echo " ###### creating backups folder"
	mkdir -p $BACKUP_STOR/.gd
	cp $BACKUP_SECRETS/.gd_credentials.json $BACKUP_STOR/.gd/credentials.json
fi;

echo " ###### Checking backup folders .. "
echo $BACKUP_FOLDERS

echo " ###### Running backup "
if [ ! -z $DEST_PATH ]; then
	echo "Creating folder $DEST_PATH "
	mkdir -p $DEST_PATH;
fi;

for f in "$BACKUP_FOLDERS" ; do
	echo tar -C $BACKUP_LOCAL czf $DEST_PATH/$SERVICE_NAME-$STAMP.$BKP_EXT $f
	tar -C $BACKUP_LOCAL -czf $DEST_PATH/$SERVICE_NAME-$STAMP.$BKP_EXT $f
done;

echo "Backed up file: "
ls -al $DEST_PATH/$SERVICE_NAME-$STAMP.$BKP_EXT

#echo " ###### let's give it a shot! "
#cd $BACKUP_STOR
#zcat $DEST_PATH/$SERVICE_NAME-$STAMP.sql.gz | gdrive push -piped -force -destination $BACKUP_REMOTE_PATH $SERVICE_NAME.$BKP_EXT


