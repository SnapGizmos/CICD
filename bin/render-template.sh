#!/usr/bin/bash

if [ -z "$1" ]; then
	echo "Missing required parameter NAMESPACE as first argument";
	exit -1;
fi;
NAMESPACE=$1

if [ -z "$2" ]; then
	echo "Missing required parameter TEMPLATE as first argument";
	exit -1;
fi;
TEMPLATE=$2

echo "Loading environment for $NS_LONG ";
set -o allexport
source env/$NAMESPACE/dev
set +o allexport

for p in $(oc process --parameters -n $NAMESPACE $TEMPLATE | grep -oh "^\w*" | grep -v "^NAME$"); do
	echo "P: $p";
	str="echo \$$p";
	v=$(eval $str);
	if [ ! -z "$v" ]; then
		if [ ! -z "$PARAMS" ]; then PARAMS="$PARAMS "; fi;
		PARAMS="$PARAMS$p=$v";
		echo "PARAMS: $PARAMS ";
	fi;
done;

echo oc process -n $NAMESPACE $TEMPLATE $PARAMS
oc process -n $NAMESPACE $TEMPLATE $PARAMS | oc create -f -

