VERSION := 0.3.0-dyne

# APP setup
APP_DOCKER_URL := dyne
APPS := $(wildcard *.app)

# tarantool operator
OPVER := 0.0.9
OPREPO := dyne/tarantool-operator
OPNS := tarantool-operator
# DOCKER_BASE := dyne/tarantool:centos8
