#!/bin/bash

echo 1: $1
echo 0: $0

if [ -z "$1" ]; then
	echo "Missing backup name";
	exit -1;
fi;
JOB=$1;

echo "job $JOB"
oc process $JOB ID=`date +%Y%m%d%H%M` | oc create -f -

