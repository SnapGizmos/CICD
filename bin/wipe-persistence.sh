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

echo "$NS_LONG : Deleting claims ";
for pvc in $(oc get pvc -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	echo "$NS_LONG : Claim $pvc.. ";
	oc delete pvc $pvc;
	echo "$NS_LONG : $pvc .. ok ";
done;

echo "$NS_LONG : Inspecting volumes ";
for pv in $(oc get pv -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	echo "$NS_LONG : Testing volume $pv assignment to $NS .. ";
	FILE=$(grep -r $pv pv/$NS/ | awk -F ':' '{{print $1}}' | head -1);
	if [ ! -z "$FILE" ]; then
		POOL=$(grep "pool" $FILE | awk -F ':' '{{ print $2}}' | tr -d '[:space:]')
		IMG=$(grep "image" $FILE | awk -F ':' '{{ print $2}}' | tr -d '[:space:]')
		echo "$NS_LONG : wiping $pv assignment to $NS  ";
		oc delete pv $pv;
		DEV=$(sudo rbd map $POOL/$IMG);
		if [ ! -z "$DEV" ]; then
			echo "$NS_LONG : formatting $pv on volume $POOL/$IMG ";
			sudo mkfs.ext4 -F $DEV;
			sudo rbd unmap $DEV;
		fi;
	fi;
	echo "$NS_LONG : $pv .. ok ";
done;

