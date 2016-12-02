#!/bin/bash

NS="poclab"
NS_LONG="POC Lab"

bin/cleanup.sh $NS "$NS_LONG"
prj=$(oc get project/$NS -o name 2>/dev/null)
if [ -z "$prj" ]; then
	echo "Creating new project $NS_LONG ... ";
	oc new-project $NS --display-name="$NS_LONG"
	echo "ok";

	bin/create-persistence.sh $NS "$NS_LONG"
fi;

echo "Loading environment for $NS_LONG ";
set -o allexport
source env/$NS/dev
set +o allexport

for prv in $(find secrets/$NS -maxdepth 1 -type f -name '*.json' -o -name '*.yml' -o -name '*.yaml' ); do
	echo "$NS_LONG : Creating Secret $prv ... ";
	oc create -f $prv;
	echo "ok";
done;

bin/configmap.sh $NS "$NS_LONG"

for pv in $(find pv/$NS -maxdepth 1 -type f -name '*.json' -o -name '*.yml' -o -name '*.yaml' ); do
	echo "$NS_LONG : Creating PV $pv ... ";
	oc create -f $pv;
	echo "ok";
done;

for fl in $(find objects/$NS/. -maxdepth 1 -type f -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.sh' | sort); do
	if [ -z $(echo $fl | grep '.sh$') ]; then
		echo "$NS_LONG : Creating $fl ... ";
		oc create -f $fl;
		echo "ok";
	else
		echo "$NS_LONG : Running $fl ... ";
		sh -c $fl;
		echo "ok";
	fi;
done;

