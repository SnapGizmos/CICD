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

	echo "$NS_LONG : Inspecting volumes ";
	for pv in $(oc get pv -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
		echo "$NS_LONG : Inspecting $pv .. ";
		if [ ! -z "$(grep -r $pv pv/$NS/)" ]; then
			oc delete pv $pv;
		fi;
		echo "$NS_LONG : $pv .. ok ";
	done;

