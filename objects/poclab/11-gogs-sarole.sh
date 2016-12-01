#!/usr/bin/bash

oc adm policy add-scc-to-user privileged -z gogs
