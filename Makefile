include config.mk

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile
#	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' benchmark/Makefile

show-config: ## Show the current configuration
	@echo "VERSION: ${VERSION}"
	@echo "APP DOCKER: ${APP_DOCKER_URL}/APP-name:${APP_DOCKER_VER}"
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
	REPO=${OPREPO} VERSION=${OPVER} \
	 make -C tarantool-operator build
	REPO=${OPREPO} VERSION=${OPVER} \
	 make -C tarantool-operator docker-build

docker-push: ## Push docker to repo (default needs credentials)
	docker push ${OPREPO}:${OPVER}

install-kube: OPCHART := tarantool-operator/helm-charts/tarantool-operator
install-kube: ## Helm install operator on Kubernetes
	sed -e "s/@@VERSION@@/0.0.9-dyne/g" \
	skel/operator-values.yaml > ${OPCHART}/values.yaml
	helm install -n ${OPNS} operator ${OPCHART} \
		--create-namespace \
		--set image.repository=${OPREPO} \
		--set image.tag=${OPVER}

uninstall-kube: ## Helm uninstall operator on Kubernetes
	helm uninstall -n ${OPNS} operator

uninstall-all: ## Helm uninstall all apps
	for i in $(basename ${APPS}); do \
	helm status -n zenswarm-$$i $$i \
	&& helm uninstall -n zenswarm-$$i $$i; done
	helm uninstall -n ${OPNS} operator

##@ Cluster administration
list: ## List all apps in our namespaces
	@for i in $(basename ${APPS}); do \
		echo "APP: \033[36m$$i\033[0m"; \
		kubectl get all --namespace zenswarm-$$i; \
	done

list-pods: ## List pods in our namespace
	@for i in $(basename ${APPS}); do \
		echo "APP: \033[36m$$i\033[0m"; \
		kubectl get pods --namespace zenswarm-$$i; \
	done

list-all: ## List all in all namespaces
	kubectl get all --all-namespaces

logs:
	@for i in $(basename ${APPS}); do \
		echo "APP: \033[36m$$i\033[0m"; \
		pods=`kubectl get pods --namespace zenswarm-$$i | awk '/^NAME/{next} /^controller/{next} {print $$1}'`; \
		for p in $$pods; do \
			echo "pod: \033[36m$$p\033[0m"; \
			kubectl logs $$p --namespace zenswarm-$$i; \
		done; \
		echo $$pods; \
	done

app-port-forward: app-check ## Open access to APP via localhost (Ctrl-C to stop)
	kubectl port-forward routers-0-0 -n zenswarm-${APP} --address 0.0.0.0 8081

app-check:
	$(if ${APP},,$(error "APP name undefined"))
	$(if $(wildcard ${APP}.app),, $(error "Cannot find app: ${APP}.app"))

app-hash: app-check
	find ${APP}.app/cartridge -type f -print0 | sort -z | \
		xargs -0 sha1sum | sha1sum | awk '{print $$1}' > ${APP}.app/tag.sha

##@ App management

app-create: ## Create a new app with APP
	$(if ${APP},,$(error "APP name undefined"))
	$(if $(wildcard ${APP}.app), $(error "cannot overwrite app: ${APP}.app"))
	@echo "Zenswarm create new app: ${APP}.app"
	@$(call create-app,${APP},${VERSION})
	cartridge create ${APP}.app --name ${APP} \
	&& mv ${APP}.app/${APP} ${APP}.app/cartridge
	@echo "FROM centos:7" > ${APP}.app/cartridge/Dockerfile.build.cartridge
	@echo "FROM dyne/tarantool:centos8" > ${APP}.app/cartridge/Dockerfile.cartridge
	@ln -s cartridge/app/roles/custom.lua ${APP}.app/main.lua

app-defaults: app-check ## Reset defaults in an existing app with APP
	@echo "Zenswarm reset app: ${APP}.app"
	@$(call create-app,${APP},${VERSION})

app-build: APP_HASH := $(file <${APP}.app/tag.sha)
app-build: app-hash ## Build Docker image from APP/cartridge
	sed -i -e "0,/ZENSWARM_TAG/{s/ZENSWARM_TAG.*/ZENSWARM_TAG='${APP_HASH}'/}" \
	${APP}.app/cartridge/app/roles/custom.lua
	cartridge pack docker ${APP}.app/cartridge \
	 --tag dyne/zenswarm-${APP}:${APP_HASH} --verbose
	@echo "Zenswarm build app: dyne/zenswarm-${APP}:${APP_HASH}"

app-push: APP_HASH := $(file <${APP}.app/tag.sha)
app-push: app-check ## Push the Docker image of APP
	docker push ${APP_DOCKER_URL}/zenswarm-${APP}:${APP_HASH}

app-install: APP_HASH := $(file <${APP}.app/tag.sha)
app-install: app-check ## Install the Helm APP/chart in namespace zenswarm-APP
	sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm install -n zenswarm-${APP} benchmark ${APP}.app/chart --create-namespace 

#--set LuaMemoryReserveMB=${RESMB}

app-upgrade: APP_HASH := $(file <${APP}.app/tag.sha)
app-upgrade: app-check ## Upgrade the Helm APP/chart in namespace zenswarm-APP
	sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm upgrade -n zenswarm-${APP} benchmark ${APP}.app/chart \
	--set image.tag=${APP_HASH} --set imagePullPolicy=Always \
	--dependency-update --devel

app-upgrade-force: APP_HASH := $(file <${APP}.app/tag.sha)
app-upgrade-force: app-check ## Upgrade the Helm APP/chart in namespace zenswarm-APP
	sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm upgrade -n zenswarm-${APP} benchmark ${APP}.app/chart \
	--set image.tag=${APP_HASH} --set imagePullPolicy=Always --create-namespace \
	--recreate-pods

app-status: app-check ## Check the status of installed APP
	helm status -n zenswarm-${APP} ${APP}

app-uninstall: ## Uninstall the APP
	helm uninstall -n zenswarm-${APP} ${APP}
