#!/usr/bin/bash

for p in $(oc process --parameters -n poclab gogs-mysql-template | grep -oh "^\w*" | grep -v "^NAME$"); do
	echo "P: $p";
	str="echo \$$p";
	v=$(eval $str);
	if [ ! -z "$v" ]; then
		if [ ! -z "$PARAMS" ]; then PARAMS="$PARAMS,"; fi;
		PARAMS="$PARAMS$p=$v";
		echo "PARAMS: $PARAMS ";
	fi;
done;

echo oc process -n poclab -v $PARAMS gogs-mysql-template 
oc process -n poclab -v $PARAMS gogs-mysql-template | oc create -f -

