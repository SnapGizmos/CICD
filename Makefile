
OC = $(shell which oc)
PRJ = $(shell echo poclab)
CONFIG_MAPS = $(shell find configmaps/$(PRJ)/* -maxdepth 0 -type d)

.PHONY: all
.DEFAULT_GOAL := all

upload-secrets:
	test -d secrets && tar czf - secrets | bin/gdrive push -piped -force SnapGizmos/Infrastructure/Secrets/CICD.tar.gz; 

secrets:
	bin/gdrive pull -piped SnapGizmos/Infrastructure/Secrets/CICD.tar.gz | tar xzf -;

all:
	bin/poclab-recycle.sh

configmap: $(CONFIG_MAPS)
	bin/poclab-recycle.sh
