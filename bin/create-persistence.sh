#!/bin/bash

if [ -z $1 ]; then
	echo "Missing parameter: namespace ";
	exit 0;
else
	NS=$1
	NS_LONG=$2
fi;

for prv in $(find secrets/$NS -maxdepth 1 -type f -name '*.json' -o -name '*.yml' -o -name '*.yaml' ); do
	echo "$NS_LONG : Creating Secret $prv ... ";
	oc create -f $prv;
	echo "ok";
done;

for pv in $(find pv/$NS -maxdepth 1 -type f -name '*.json' -o -name '*.yml' -o -name '*.yaml' ); do
	echo "$NS_LONG : Creating PV $pv ... ";
	oc create -f $pv;
	echo "ok";
done;

