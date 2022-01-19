include ../config.mk

# TODO: tune lua memory reserve
RESMB := 8

# recursive unique hash a whole directory
hash = $(shell rm -f ${1}.sha && find . -type f -print0 \
	| sort -z | xargs -0 sha256sum | sha256sum \
	> ${1}.sha)

##@ General
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile

##@ Benchmark app
all: build

build: ## Build and install @@APPNAME@@
	cartridge pack docker cartridge --tag dyne/zenswarm-@@APPNAME@@:latest --verbose

push:
	docker push dyne/zenswarm-@@APPNAME@@:latest

install: ## Helm install
	helm install -n ${NAMESPACE} @@APPNAME@@ chart \
		--create-namespace --set LuaMemoryReserveMB=${RESMB}

upgrade: ## Helm upgrade
	helm upgrade -n ${NAMESPACE} @@APPNAME@@ chart \
		--create-namespace --set LuaMemoryReserveMB=${RESMB}

status: ## Helm status
	helm status -n ${NAMESPACE} @@APPNAME@@

uninstall: ## Helm uninstall
	helm uninstall -n ${NAMESPACE} @@APPNAME@@

# https://stackoverflow.com/questions/33349078/make-execute-2nd-rule-only-if-1st-changed-file
#.PHONY: FORCE
# head.sha: FORCE
# 	@echo "Computing hash"
# 	$(call hash,head)
# 	@cat head.sha
