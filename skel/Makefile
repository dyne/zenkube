include ../config.mk

# TODO: tune lua memory reserve
RESMB := 8

# recursive unique hash a whole directory
hash = $(shell rm -f ${1}.sha && find . -type f -print0 \
	| sort -z | xargs -0 sha256sum | sha256sum \
	> ${1}.sha)

##@ Benchmark app
all: build

build: ## Build and install @@APPNAME@@
	cartridge pack docker cartridge --tag dyne/zenswarm-@@APPNAME@@:latest --verbose

install: ## Helm install benchmark
	helm install -n ${NAMESPACE} @@APPNAME@@ chart \
		--create-namespace --set LuaMemoryReserveMB=${RESMB}

upgrade: ## Upgrade benchmark if changed
	helm upgrade -n ${NAMESPACE} @@APPNAME@@ chart \
		--create-namespace --set LuaMemoryReserveMB=${RESMB}

# https://stackoverflow.com/questions/33349078/make-execute-2nd-rule-only-if-1st-changed-file
#.PHONY: FORCE
# head.sha: FORCE
# 	@echo "Computing hash"
# 	$(call hash,head)
# 	@cat head.sha
