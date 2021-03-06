#!/bin/bash

set -x
# Use the oc client to get the url for the gogs and jenkins route and service
GOGSSVC=$(oc get svc gogs -o template --template='{{.spec.clusterIP}}')
GOGSROUTE=$(oc get route gogs -o template --template='{{.spec.host}}')
JENKINSSVC=$(oc get svc jenkins -o template --template='{{.spec.clusterIP}}')
DBSERVICE_NAME=mysql

# Use the oc client to get the postgres and jenkins variables into the current shell
eval $(oc env dc/$DBSERVICE_NAME --list | grep -v \\#)
#eval $(oc env dc/jenkins --list | grep -v \\#)

wait_service $DBSERVICE_NAME
wait_service "gogs"

# we might catch the router before it's been updated, so wait just a touch
# more
sleep 10

# RETURN=$(curl -o /dev/null -sL -w "%{http_code}" http://$GOGSSVC:3000/install \
# RETURN=$(curl -o /dev/null -sL -v http://$GOGSSVC:3000/install \
RETURN=$(curl -o /dev/null -sL --post302 -w "%{http_code}" http://$GOGSSVC:3000/install \
--form db_type=MySQL \
--form db_host=$DBSERVICE_NAME:3306 \
--form db_user=$MYSQL_USER \
--form db_passwd=$MYSQL_PASSWORD \
--form db_name=default \
--form ssl_mode=disable \
--form db_path=data/gogs.db \
--form "app_name=Gogs: Go Git Service" \
--form repo_root_path=/data/gogs/gogs-repositories \
--form run_user=git \
--form domain=localhost \
--form ssh_port=22 \
--form http_port=3000 \
--form app_url=http://${GOGSROUTE}/ \
--form log_root_path=/data/gogs/log \
--form admin_name=gogs \
--form admin_passwd=$GOGS_PASSWORD \
--form admin_confirm_passwd=$GOGS_PASSWORD \
--form admin_email=admin@gogs.com)

if [ $RETURN != "200" ]
then
	if [ $RETURN = "404" ]; then 
		echo "Looks like gogs has already been installed ";
		exit 0; 
	else 
		exit 255;
	fi;
fi

sleep 10

echo "Sorry. Not importing any repo from anywere ... "
exit 0

# import github repository
cat <<EOF > /tmp/data.json
{
      	"clone_addr": "https://github.com/Titerote/config-server-poc.git",
      	"uid": 1,
      	"repo_name": "config-server-poc"
}
EOF

RETURN=$(curl -o /dev/null -sL -w "%{http_code}" -H "Content-Type: application/json" \
-u gogs:$GOGS_PASSWORD -X POST http://$GOGSSVC:3000/api/v1/repos/migrate -d @/tmp/data.json)

if [ $RETURN != "201" ]
then
      	exit 255
fi

sleep 5

# add webhook to Gogs to trigger pipeline on push
cat <<EOF > /tmp/data.json
{
      	"type": "gogs",
      	"config": {
    	"url": "http://admin:$JENKINS_PASSWORD@$JENKINSSVC/job/tasks-cd-pipeline/build?delay=0sec",
    	"content_type": "json"
	},
	"events": [
		"push"
	],
	"active": true
}
EOF
RETURN=$(curl -o /dev/null -sL -w "%{http_code}" -H "Content-Type: application/json" \
-u gogs:$GOGS_PASSWORD -X POST http://$GOGSSVC:3000/api/v1/repos/gogs/config-server-poc/hooks -d @/tmp/data.json)

if [ $RETURN != "201" ]
then
      	exit 255
fi

