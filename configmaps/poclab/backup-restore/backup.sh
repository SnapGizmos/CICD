#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${BACKUP_LOCAL:=/data/local}
echo ${BACKUP_REMOTE_PATH:=SnapGizmos/Backups/}
echo ${BACKUP_NAMESPACE:=$(oc describe pod $HOSTNAME|grep ^Namespace|awk -F ':' '{{print $2}}'|tr -d '[:space:]')}
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
	mkdir -p $DEST_PATH/.gd
	cp $BACKUP_SECRETS/.gd_credentials.json $DEST_PATH/.gd/credentials.json
done;

echo "Backed up file: "
ls -al $DEST_PATH/$SERVICE_NAME-$STAMP.$BKP_EXT

echo "###### let's give it a shot! at $BACKUP_STOR "
cd $DEST_PATH
ln -s $SERVICE_NAME-$STAMP.$BKP_EXT $BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT
echo "Uploading $BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT to $BACKUP_REMOTE_PATH .. "
gdrive push -ignore-checksum=false -no-prompt -verbose -force -destination $BACKUP_REMOTE_PATH $BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT
echo "listing $BACKUP_REMOTE_PATH .. "
gdrive list $BACKUP_REMOTE_PATH
#zcat $DEST_PATH/$SERVICE_NAME-$STAMP.sql.gz | gdrive push -piped -force -destination $BACKUP_REMOTE_PATH $SERVICE_NAME.$BKP_EXT
#rm -rf $DEST_PATH/.gd

echo " ########################################## "
echo " ############ END of Script ############### "
