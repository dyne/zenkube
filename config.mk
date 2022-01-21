
VERSION := 0.2.0-dyne
NAMESPACE := tarantool

# APP setup
APP_DOCKER_URL := dyne
APP_DOCKER_VER := latest
APPS := $(wildcard *.app)

# tarantool operator
OPVER := 0.0.9-dyne
OPREPO := dyne/tarantool-operator
OPNS := tarantool-operator
# DOCKER_BASE := dyne/tarantool:centos8
# DOCKER_TARGET := dyne/zenswarm:${VERSION}

# && sed -e "s/@@APPNAME@@/${1}/g" skel/Makefile > ${1}.app/Makefile

create-app = mkdir -p ${1}.app/chart \
	&& sed -e "s/@@APPNAME@@/${1}/g" skel/chart/Chart.yaml \
	|  sed -e "s/@@VERSION@@/${VERSION}/g" > ${1}.app/chart/Chart.yaml \
	&& sed -e "s/@@APPNAME@@/${1}/g" skel/chart/values.yaml \
	|  sed -e "s/@@VERSION@@/${VERSION}/g" > ${1}.app/chart/values.yaml \
	&& cp -ra skel/chart/templates ${1}.app/chart/

# recursive unique hash a whole directory
hash-app = find $1/cartridge -type f -print0 | sort -z | \
	xargs -0 sha1sum | sha1sum | awk '{print $$1}' > $1/tag.sha
