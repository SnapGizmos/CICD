#!/bin/bash

NS="poclab"
NS_LONG="POC Lab"

prj=$(oc get project/$NS -o name 2>/dev/null)
if [ ! -z "$prj" ]; then
	echo "Project $NS_LONG exists. Deleting: ";
	oc delete project $NS;
	while [ ! -z "$(oc get project $NS -o name 2>/dev/null)" ]; do
		echo "Waitting ... ";
		sleep 10;
	done;
	echo "ok";
	echo "$NS_LONG : Inspecting volumes ";
	for pv in $(oc get pv -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
		echo "$NS_LONG : Inspecting $pv .. ";
		if [ ! -z "$(grep -r $pv pv/$NS/)" ]; then
			oc delete pv $pv;
		fi;
		echo "$NS_LONG : $pv .. ok ";
	done;
fi;

echo "Loading environment for $NS_LONG ";
set -o allexport
source env/$NS/dev
set +o allexport

echo "Creating new project $NS_LONG ... ";
oc new-project $NS --display-name="$NS_LONG"
echo "ok";

for prv in $(find secrets/$NS -maxdepth 1 -type f -name '*.json' -o -name '*.yml' -o -name '*.yaml' ); do
	echo "$NS_LONG : Creating Secret $prv ... ";
	oc create -f $prv;
	echo "ok";
done;

PARAMS=""
for cfg in $(find configmaps/$NS/* -maxdepth 0 -type d ); do
	echo "$NS_LONG : Creating ConfigMap from folder ($cfg) with $PARAMS ";
	for cfg2 in $(find $cfg/. -maxdepth 1 -type f -name '*.sh'); do
		#echo "Running with $cfg2 and $PARAMS"
		PARAMS="$PARAMS --from-file=$cfg2"
	done;
	if [ ! -z "$PARAMS" ]; then
		#echo basename: $(basename $cfg)
		echo oc create configmap $(basename $cfg) $PARAMS;
	fi;
	echo "ok";
done;

for cfg in $(find configmaps/$NS -maxdepth 1 -type f -name '*.sh'); do
	echo "$NS_LONG : Creating ConfigMap $cfg ... ";
	oc create configmap $(basename $cfg) --from-file=$cfg;
	echo "ok";
done;

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

