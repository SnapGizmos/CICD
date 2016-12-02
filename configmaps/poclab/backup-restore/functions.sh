#!/bin/bash

function wait_service {
	SERVICE_NAME=$1
	# this db has a readiness probe, so checking if there is at least one
	# endpoint means it is alive and ready, so we can then attempt to install gogs
	# we're willing to wait 60 seconds for it, otherwise something is wrong.
	x=1
	oc get ep $SERVICE_NAME -o yaml | grep "\- addresses:"
	while [ ! $? -eq 0 ]
	do
		sleep 10
		x=$(( $x + 1 ))
		
		if [ $x -gt 100 ]
		then
			exit 255
		fi
		
		oc get ep $SERVICE_NAME -o yaml | grep "\- addresses:"
	done
}

function wait_service_pods {
	SERVICE_NAME=$1
	# this db has a readiness probe, so checking if there is at least one
	# endpoint means it is alive and ready, so we can then attempt to install gogs
	# we're willing to wait 60 seconds for it, otherwise something is wrong.
	x=1
	SELECTOR=$(oc describe service $SERVICE_NAME | grep "^Selector" | awk -F ':' '{{ print $2 }}'|tr -d '[:space:]')
	oc describe pod -l $SELECTOR
	echo "-- End function wait_service_pods "
}

