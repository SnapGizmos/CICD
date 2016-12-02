#!/bin/bash

set -x
# Use the oc client to get the url for the gogs and jenkins route and service
GOGSSVC=$(oc get svc gogs -o template --template='{{.spec.clusterIP}}')
GOGSROUTE=$(oc get route gogs -o template --template='{{.spec.host}}')
JENKINSSVC=$(oc get svc jenkins -o template --template='{{.spec.clusterIP}}')
DBSERVICE_NAME=mysql

job=$(oc describe pod $HOSTNAME | grep job-name | awk -F '=' '{{ print $2 }}'|tr -d '[:space:]')
echo "WE are in JOB $job "
nruns=$(oc get pods -l job-name=$job | grep -v ^NAME | wc -l)
echo "which is run $nruns "
if [ $nruns -ge 10 ]; then
	echo "GIVING UP, it's been $nruns tries ... declaring PHONY success ";
	exit 0;
fi;

# Use the oc client to get the postgres and jenkins variables into the current shell
eval $(oc env dc/$DBSERVICE_NAME --list | grep -v \\#)
#eval $(oc env dc/jenkins --list | grep -v \\#)

# postgres has a readiness probe, so checking if there is at least one
# endpoint means postgres is alive and ready, so we can then attempt to install gogs
# we're willing to wait 60 seconds for it, otherwise something is wrong.
x=1
oc get ep $DBSERVICE_NAME -o yaml | grep "\- addresses:"
while [ ! $? -eq 0 ]
do
      	sleep 10
      	x=$(( $x + 1 ))
	
      	if [ $x -gt 100 ]
      	then
	    	exit 255
      	fi
	
      	oc get ep $DBSERVICE_NAME -o yaml | grep "\- addresses:"
done

# now we wait for gogs to be ready in the same way
x=1
oc get ep gogs -o yaml | grep "\- addresses:"
while [ ! $? -eq 0 ]
do
      	sleep 10
      	x=$(( $x + 1 ))
	
      	if [ $x -gt 100 ]
      	then
	    	exit 255
      	fi
	
      	oc get ep gogs -o yaml | grep "\- addresses:"
done

if [ ! -z "$JOB_FAIL_DEPENDENCY" ]; then
	#oc describe pods -l job-name=$JOB_FAIL_DEPENDENCY;
	inloop='true'
	while [ $inloop = 'true' ]; do
		for job in "$JOB_FAIL_DEPENCENCY"; do
			status=$(oc describe pods -l job-name=$job | grep ^Status | awk -F ':' '{{print $2}}' | tr -d '[:space:]')
			if [ -z "$status" ]; then
				echo "Dependant job ($job) does not exist, can't continue. ";
				exit -1;
			fi;

			case "$status" in 
				Succeeded)
					echo "Hello there, everything went well ... job $JOB_FAIL_DEPENDENCY finalized with status $status " 
					exit 0
					;;
				Running)
					echo "Still working, I suggest sleeping for a few ... " 
					sleep 10
					;;
				*)
					echo "Unrecognized status : $status , letting it go .. " 
					inloop='false'
					;;
			esac
		done;
	done;
fi;

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
--form http_port=80 \
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

