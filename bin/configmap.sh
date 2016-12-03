#!/bin/bash

if [ -z $1 ]; then
	echo "Missing parameter: namespace ";
	exit 0;
else
	NS=$1
	NS_LONG=$2
fi;

#NS="poclab"
#NS_LONG="POC Lab"

echo "Loading environment for $NS_LONG ";
set -o allexport
source env/$NS/dev
set +o allexport

PARAMS=""
for cfg in $(find configmaps/$NS/* -maxdepth 0 -type d ); do
	echo "$NS_LONG : Creating ConfigMap from folder ($cfg) with $PARAMS ";
	for cfg2 in $(find $cfg/. -maxdepth 1 -type f -name '*.sh'); do
		#echo "Running with $cfg2 and $PARAMS"
		PARAMS="$PARAMS --from-file=$cfg2"
	done;
	if [ ! -z "$PARAMS" ]; then
		#echo basename: $(basename $cfg)
		if [ ! -z "$(oc get configmap/$(basename $cfg) -o name)" ]; then
			oc delete configmap/$(basename $cfg)
		fi;
		oc create configmap $(basename $cfg) $PARAMS;
	fi;
	echo "ok";
done;

echo "TEST: confimaps/$NS/\..*"
find configmaps/$NS -maxdepth 1 -type f | grep -v "confimaps/$NS/\\\..*"

for cfg in $(find configmaps/$NS -maxdepth 1 -type f | grep -v "confimaps/$NS/\..*"); do
	echo "$NS_LONG : Creating ConfigMap $cfg ... ";
	if [ ! -z "$(oc get configmap/$(basename $cfg) -o name 2>/dev/null)" ]; then
		oc delete configmap/$(basename $cfg)
	fi;
	oc create configmap $(basename $cfg) --from-file=$cfg;
	echo "ok";
done;

