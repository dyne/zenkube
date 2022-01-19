# CHARTS_DIR := $(shell pwd)/charts tarantool-operator/helm-charts
VERSION := 0.1.0-dyne
NAMESPACE := tarantool
OPVERSION := 0.0.9-dyne
OPREPO := dyne/tarantool-operator
APPS := $(wildcard *.app)
# DOCKER_BASE := dyne/tarantool:centos8
# DOCKER_TARGET := dyne/zenswarm:${VERSION}

create-app = mkdir -p ${1}.app/chart \
	&& sed -e "s/@@APPNAME@@/${1}/g" skel/Makefile > ${1}.app/Makefile \
	&& sed -e "s/@@APPNAME@@/${1}/g" skel/chart/Chart.yaml \
	|  sed -e "s/@@VERSION@@/${VERSION}/g" > ${1}.app/chart/Chart.yaml \
	&& sed -e "s/@@APPNAME@@/${1}/g" skel/chart/values.yaml \
	|  sed -e "s/@@VERSION@@/${VERSION}/g" > ${1}.app/chart/values.yaml \
	&& cp -ra skel/chart/templates ${1}.app/chart/

list-pods = $(shell kubectl get pods --namespace ${NAMESPACE} \
	| awk '/^NAME/{next} /^controller/{next} {print $$1}')

list-controllers = $(shell kubectl get pods --namespace ${NAMESPACE} \
	| awk '/^controller/{print $$1} {next}')

