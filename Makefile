include config.mk

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' build/cluster.mk

include build/cluster.mk

show-config: ## Show the current configuration
	@echo "VERSION: ${VERSION}"
	@echo "APP DOCKER: ${APP_DOCKER_URL}/APP-name:${APP_DOCKER_VER}"

install-deps: ## install dependencies: golang, kubectl, helm (needs root)
	@apt-get install -y golang kubernetes-client
	@if ! command -v helm; then \
	curl -sL https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz -o - \
	> helm-v3.7.2-linux-amd64.tar.gz \
	&& tar -xf helm-v3.7.2-linux-amd64.tar.gz \
	&& mv linux-amd64/helm /usr/local/bin/ && chmod +x /usr/local/bin/helm; fi

##@ App management

app-check:
	$(if ${APP},,$(error "APP name undefined"))
	$(if $(wildcard ${APP}.app),,$(error "Cannot find app: ${APP}.app"))
	@echo "APP:  \033[36m${APP}\033[0m"
	@echo "TAG: `cat ${APP}.app/tag.sha`" $(file <${APP}.app/tag.sha)

app-hash: app-check
	@find ${APP}.app/cartridge -type f -print0 | sort -z | \
		xargs -0 sha1sum | sha1sum | awk '{print $$1}' | tee > ${APP}.app/tag.sha
	@echo "NEW: " $(file <${APP}.app/tag.sha)

app-check-empty:
	$(if ${APP},,$(error "APP name undefined"))
	$(if $(wildcard ${APP}.app), $(error "cannot overwrite app: ${APP}.app"))

app-create-cartridge:
	@mkdir -p ${APP}.app/chart
	cartridge create ${APP}.app --name ${APP} \
	&& mv ${APP}.app/${APP} ${APP}.app/cartridge
	@echo "FROM centos:8" > ${APP}.app/cartridge/Dockerfile.build.cartridge
	@echo "FROM dyne/tarantool:centos8" > ${APP}.app/cartridge/Dockerfile.cartridge
	@ln -s cartridge/app/roles/custom.lua ${APP}.app/main.lua

app-create-chart:
	@mkdir -p ${APP}.app/chart
	@sed -e "s/@@APPNAME@@/${APP}/g" skel/chart/Chart.yaml \
	| sed -e "s/@@VERSION@@/${VERSION}/g" > ${APP}.app/chart/Chart.yaml
	@sed -e "s/@@APPNAME@@/${APP}/g" skel/chart/values.yaml \
	| sed -e "s/@@VERSION@@/${VERSION}/g" > ${APP}.app/chart/values.yaml
	@cp -ra skel/chart/templates ${APP}.app/chart/

app-create: app-check-empty app-create-cartridge app-hash ## Create a new app with APP

app-defaults: app-check app-create-chart ## Reset defaults in an existing app with APP
	@echo "Zenswarm reset app: ${APP}.app"

app-build: APP_HASH := $(file <${APP}.app/tag.sha)
app-build: app-check ## Build Docker image from APP/cartridge
	sed -i -e "0,/ZENSWARM_TAG/{s/ZENSWARM_TAG.*/ZENSWARM_TAG='${APP_HASH}'/}" \
	${APP}.app/cartridge/app/roles/custom.lua
	cartridge pack docker ${APP}.app/cartridge \
	 --tag dyne/zenswarm-${APP}:${APP_HASH}
	@echo "Zenswarm build app: dyne/zenswarm-${APP}:${APP_HASH}"

app-push: APP_HASH := $(file <${APP}.app/tag.sha)
app-push: app-check ## Push the Docker image of APP
	docker push ${APP_DOCKER_URL}/zenswarm-${APP}:${APP_HASH}

app-install: APP_HASH := $(file <${APP}.app/tag.sha)
app-install: app-check ## Install the Helm APP/chart in namespace zenswarm-APP
	sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm install -n zenswarm-${APP} ${APP} ${APP}.app/chart --create-namespace 

app-port-fwd: app-check ## Open access to APP via localhost (Ctrl-C to stop)
	kubectl port-forward routers-0-0 -n zenswarm-${APP} --address 0.0.0.0 8081

app-list: app-check
	kubectl get all --namespace zenswarm-${APP};

app-logs: app-check ## Show logs of all running pods of APP
	@pods=`kubectl get pods --namespace zenswarm-${APP} | awk '/^NAME/{next} /^controller/{next} {print $$1}'`; \
	for p in $$pods; do \
		echo "pod: \033[36m$$p\033[0m"; \
		kubectl logs $$p --namespace zenswarm-${APP}; \
	done

app-restart: app-uninstall app-install

app-upgrade: APP_HASH := $(file <${APP}.app/tag.sha)
app-upgrade: app-check
	sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm upgrade -n zenswarm-${APP} @{APP} ${APP}.app/chart \
	--set image.tag=${APP_HASH} --set imagePullPolicy=Always \
	--recreate-pods

app-upgrade-f: APP_HASH := $(file <${APP}.app/tag.sha)
app-upgrade-f: app-check
	sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm upgrade -n zenswarm-${APP} ${APP} ${APP}.app/chart \
	--set image.tag=${APP_HASH} --set imagePullPolicy=Always --create-namespace \
	--recreate-pods

app-status: app-check ## Check the status of installed APP
	helm status -n zenswarm-${APP} ${APP}

app-uninstall: ## Uninstall the APP
	helm uninstall -n zenswarm-${APP} ${APP}

app-uninstall-f: ## Force uninstall the APP (--no-hooks)
	helm uninstall -n zenswarm-${APP} ${APP} --no-hooks
