#!/usr/bin/bash

oc adm policy add-scc-to-user privileged -z bkpadm
oc adm policy add-scc-to-user anyuid -z bkpadm

