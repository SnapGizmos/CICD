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

echo "$NS_LONG : Cleaning Routes ";
for dc in $(oc get route -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	#echo "$NS_LONG : Inspecting $dc .. ";
	oc delete route $dc;
	#echo "$NS_LONG : $dc .. ok ";
done;

echo "$NS_LONG : Cleaning Services ";
for dc in $(oc get svc -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	#echo "$NS_LONG : Inspecting $dc .. ";
	oc delete svc $dc;
	#echo "$NS_LONG : $dc .. ok ";
done;

echo "$NS_LONG : Cleaning DeploymentConfigs ";
for dc in $(oc get dc -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	echo "$NS_LONG : deleting $dc .. ";
	oc delete dc $dc;
	echo "$NS_LONG : $dc .. ok ";
done;

echo "$NS_LONG : Cleaning Jobs ";
for dc in $(oc get jobs -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	echo "$NS_LONG : deleting $dc .. ";
	oc delete job $dc;
	echo "$NS_LONG : $dc .. ok ";
done;

echo "$NS_LONG : Cleaning ConfigMaps ";
for dc in $(oc get configmap -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	#echo "$NS_LONG : Inspecting $dc .. ";
	oc delete configmap $dc;
	#echo "$NS_LONG : $dc .. ok ";
done;

echo "$NS_LONG : Cleaning Templates ";
for dc in $(oc get template -n $NS -o name | awk -F '/' '{{ print $2 }}'); do
	#echo "$NS_LONG : Inspecting $dc .. ";
	oc delete template $dc;
	#echo "$NS_LONG : $dc .. ok ";
done;
