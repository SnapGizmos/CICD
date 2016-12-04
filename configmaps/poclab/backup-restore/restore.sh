#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${BACKUP_LOCAL:=/data/local}
echo ${BACKUP_REMOTE_PATH:=SnapGizmos/Backups/}
echo ${BACKUP_NAMESPACE:=$(oc describe pod $HOSTNAME|grep ^Namespace|awk -F ':' '{{print $2}}'|tr -d '[:space:]')}
source /data/scripts/functions.sh

STAMP=$(date +%Y%m%d%H%M)
SRC_PATH=$BACKUP_STOR/$SERVICE_NAME
ACTIVE_SERVICE_NAME=$(echo $SERVICE_NAME)
BKP_EXT=tgz
env

if [ "$1" = "console" ]; then
	sleep 3000;
fi;

echo "TODO: ADD variable BACKUP_NAME, and use it instead of SERVICE_NAME for the filename ";
if [ -z "$SERVICE_NAME" ]; then
	echo "Missing required field SERVICE_NAME ";
	exit -1;
fi;

test_active_service $ACTIVE_SERVICE_NAME

if [ -z "$ACTIVE_SERVICE_NAME" ]; then
	echo "Found existing active service $SERVICE_NAME ";
	eval $(oc env dc/$ACTIVE_SERVICE_NAME --list | grep -v \\#)
fi;

if [ -z "$DESTINATION_PATH" ]; then
	echo "Missing mandatory parameter DESTINATION_PATH ";
	exit -1;
fi;

echo " ###### Checking service status .. "
wait_service $ACTIVE_SERVICE_NAME
wait_service_pods $ACTIVE_SERVICE_NAME

if [ ! -d $BACKUP_STOR/.gd ]; then
	echo "First time remote backup configuration"
	mkdir -p $BACKUP_STOR/.gd
	cp $BACKUP_SECRETS/.gd_credentials.json $BACKUP_STOR/.gd/credentials.json
fi;

#find $SRC_PATH -type f
extname="*.$BKP_EXT"
BACKUP_FILE=$(find $SRC_PATH -type f -name $extname -printf '%Ts\t%p\n' | sort -nr | head -1 | awk '{{ print $2 }}')

echo " ###### Recovering from: $BACKUP_FILE to $DESTINATION_PATH " 
if [ -f "$BACKUP_FILE" ]; then
	echo tar -C $DESTINATION_PATH -xzf $BACKUP_FILE
	tar -C $DESTINATION_PATH -xzf $BACKUP_FILE
else
	echo "Backup not found under $SRC_PATH, let's recover from remote ! at $BACKUP_STOR "
	cd $BACKUP_STOR
	echo "Trying  with $BACKUP_REMOTE_PATH/$BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT from Remote gdrive "
	remote_file=$(gdrive list $BACKUP_REMOTE_PATH/$BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT )
	if [ -z "$remote_file" ]; then
		echo "!!!!!! NO BACKUPS FOUND, Aborting .. !!!!!!!!"
		exit -1;
	fi;
	echo gdrive pull -piped $BACKUP_REMOTE_PATH/$BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT \| tar -C $DESTINATION_PATH -xz
	gdrive pull -ignore-checksum=false -no-prompt -verbose -piped $BACKUP_REMOTE_PATH/$BACKUP_NAMESPACE-$SERVICE_NAME.$BKP_EXT | tar -C $DESTINATION_PATH -xz
fi;

if [ ! -z "$ACTIVE_SERVICE_NAME" ]; then
	echo "Killing pod, so it will redeploy with the restored data "
	SELECTOR=$(oc describe service $ACTIVE_SERVICE_NAME | grep "^Selector" | awk -F ':' '{{ print $2 }}'|tr -d '[:space:]')
	echo "Selector $SELECTOR "
	#echo "PLEASE RESTART Pod $(oc get pods -l $SELECTOR -o name) MANUALLY ";
	oc delete $(oc get pods -l $SELECTOR -o name)
fi;

echo " ########################################## "
echo " ############ END of Script ############### "
