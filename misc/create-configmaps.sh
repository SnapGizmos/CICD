oc create configmap backup-restore --from-file=backup.sh=backup.sh -n dev
oc create configmap backup-restore --from-file=backup.sh=backups/backup.sh
