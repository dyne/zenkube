include config.mk

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile
#	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' benchmark/Makefile

show-config: ## Show the current configuration
	@echo "NAMESPACE: ${NAMESPACE}"
	@echo "VERSION: ${VERSION}"

##@ Initialize

install-deps: ## install dependencies: golang, kubectl, helm (needs root)
	@apt-get install -y golang kubernetes-client
	@if ! command -v helm; then \
	curl -sL https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz -o - \
	> helm-v3.7.2-linux-amd64.tar.gz \
	&& tar -xf helm-v3.7.2-linux-amd64.tar.gz \
	&& mv linux-amd64/helm /usr/local/bin/ && chmod +x /usr/local/bin/helm; fi

download: SOURCE := https://github.com/tarantool/tarantool-operator
download: ## clone tarantool-operator from github
	if [ ! -r tarantool-operator ]; then git clone ${SOURCE}; \
	else cd tarantool-operator && git checkout . && git pull --rebase; fi

build: ## Build docker image
	REPO=${OPREPO} VERSION=${OPVERSION} \
	 make -C tarantool-operator build
	REPO=${OPREPO} VERSION=${OPVERSION} \
	 make -C tarantool-operator docker-build

docker-push: ## Push docker to repo (default needs credentials)
	docker push dyne/tarantool-operator:0.0.9-dyne

install-kube: OPCHART := tarantool-operator/helm-charts/tarantool-operator
install-kube: ## Helm install operator on Kubernetes
	sed -e "s/@@VERSION@@/0.0.9-dyne/g" \
	skel/operator-values.yaml > ${OPCHART}/values.yaml
	helm install -n ${NAMESPACE} operator ${OPCHART} \
		--create-namespace \
		--set image.repository=${OPREPO} \
		--set image.tag=${OPVERSION}

uninstall-kube: ## Helm uninstall operator on Kubernetes
	helm uninstall -n ${NAMESPACE} operator

uninstall-all: ## Helm uninstall all apps
	for i in $(basename ${APPS}); do \
	helm status -n ${NAMESPACE} $$i \
	&& helm uninstall -n ${NAMESPACE} $$i; done

##@ Cluster administration
list: ## List all in our namespace
	kubectl get all --namespace ${NAMESPACE}

list-pods: ## List pods in our namespace
	kubectl get pods --namespace ${NAMESPACE}

list-all: ## List all in all namespaces
	kubectl get all --all-namespaces

logs: PODS := $(call list-pods)
logs:
	@for i in ${PODS}; do \
	echo "LOG: \033[36m$$i\033[0m"; \
	kubectl logs $$i --namespace ${NAMESPACE}; \
	echo; done

open-localhost: ## Open access from localhost (Ctrl-C to stop)
	kubectl port-forward routers-0-0 -n ${NAMESPACE} --address 0.0.0.0 8081

##@ App administration
create: ## Create a new app with NAME
	$(if ${NAME},,$(error "app NAME undefined"))
	$(if $(wildcard ${NAME}.app), $(error "cannot overwrite app: ${NAME}.app"))
	@echo "Zenswarm create new app: ${NAME}.app"
	@$(call create-app,${NAME},${VERSION})
	cartridge create ${NAME}.app --name ${NAME} \
	&& mv ${NAME}.app/${NAME} ${NAME}.app/cartridge
	@echo "FROM centos:7" > ${NAME}.app/cartridge/Dockerfile.build.cartridge
	@echo "FROM dyne/tarantool:centos8" > ${NAME}.app/cartridge/Dockerfile.cartridge
	@ln -s cartridge/app/roles/custom.lua ${NAME}.app/main.lua

defaults: ## Reset defaults in an existing app with NAME
	$(if ${NAME},,$(error "app NAME undefined"))
	$(if $(wildcard ${NAME}.app),, $(error "Cannot find app: ${NAME}.app"))
	@echo "Zenswarm reset app: ${NAME}.app"
	@$(call create-app,${NAME},${VERSION})
