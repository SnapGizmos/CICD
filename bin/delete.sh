#!/bin/bash

if [ ! -z "$1" ]; then
	echo "Missing parameter: namespace ";
	exit 0;
else
	NS=$1
	NS_LONG=$2
fi;

#NS="poclab"
#NS_LONG="POC Lab"

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

