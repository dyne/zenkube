
##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile

SOURCE := https://github.com/tarantool/tarantool-operator
CHARTS_DIR := $(shell pwd)/tarantool-operator/helm-charts
REPO := dyne/tarantool-operator
VERSION := 0.0.9-dyne
NAMESPACE := tarantool
DOCKER_BASE := dyne/tarantool:centos8
DOCKER_TARGET := dyne/zenswarm:${VERSION}

show-config: ## Show the current configuration
	@echo "NAMESPACE: ${NAMESPACE}"
	@echo "SOURCE: ${SOURCE}"
	@echo "CHARTS: ${CHARTS_DIR}"

##@ Initialize

install-deps: ## install dependencies: golang, kubectl, helm (needs root)
	@apt-get install -y golang kubernetes-client
	@if ! command -v helm; then curl -sL https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz -o - \
				> helm-v3.7.2-linux-amd64.tar.gz \
	      && tar -xf helm-v3.7.2-linux-amd64.tar.gz \
	      && mv linux-amd64/helm /usr/local/bin/ && chmod +x /usr/local/bin/helm; fi

download: ## clone tarantool-operator from github
	if [ ! -r tarantool-operator ]; then git clone ${SOURCE}; fi

##@ Docker

docker-build: ## Build docker image
	REPO=${REPO} VERSION=${VERSION} \
	 make -C tarantool-operator docker-build

docker-push: ## Push docker to repo (default needs credentials)
	docker push dyne/tarantool-operator:${VERSION}

##@ Deploy on Kubernetes

deploy-operator: ## Helm install operator
	cp -v operator-helm-chart-values.yaml \
	 ${CHARTS_DIR}/tarantool-operator/values.yaml
	helm install -n ${NAMESPACE} operator $(CHARTS_DIR)/tarantool-operator \
		--create-namespace \
		--set image.repository=$(REPO) \
		--set image.tag=$(VERSION)

deploy-cartridge: ## Helm install cartridge
	cp -v cartridge-helm-chart-values.yaml \
	 ${CHARTS_DIR}/tarantool-cartridge/values.yaml
	helm install -n ${NAMESPACE} zenswarm $(CHARTS_DIR)/tarantool-cartridge \
		--create-namespace \
		--set LuaMemoryReserveMB=0 # default reserve too large

remove-operator: ## helm uninstall operator
	helm uninstall -n ${NAMESPACE} operator

remove-cartridge: ## helm uninstall cartridge
	helm uninstall -n ${NAMESPACE} example-app

##@ Cluster administration
list: ## List all in our namespace
	kubectl get all --namespace ${NAMESPACE}

list-pods: ## List pods in our namespace
	kubectl get pods --namespace ${NAMESPACE}

list-all: ## List all in all namespaces
	kubectl get all --all-namespaces

open-localhost: ## Open access from localhost (Ctrl-C to stop)
	kubectl port-forward routers-0-0 -n ${NAMESPACE} --address 0.0.0.0 8081

