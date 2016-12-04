#!/bin/bash

echo ${BACKUP_SECRETS:=/data/secrets}
echo ${BACKUP_STOR:=/data/remote}
echo ${BACKUP_LOCAL:=/data/local}
echo ${BACKUP_REMOTE_PATH:=SnapGizmos/Backups/}
echo ${BACKUP_NAMESPACE:=$(oc describe pod $HOSTNAME|grep ^Namespace|awk -F ':' '{{print $2}}'|tr -d '[:space:]')}
source /data/scripts/functions.sh

for d in $(find $BACKUP_STOR -maxdepth 2 -type d) ; do
	echo $d
done;
