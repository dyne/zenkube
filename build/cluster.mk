##@ Cluster setup

OPHASH := tarantool-operator/tag.sha

op-download: SOURCE := https://github.com/tarantool/tarantool-operator
op-download: ## clone tarantool-operator from github
	if [ ! -r tarantool-operator ]; then git clone ${SOURCE}; \
	else cd tarantool-operator && git checkout . && git pull --rebase; fi

op-hash:
	@oldhash=$(shell cat tarantool-operator/tag.sha); \
	newhash=$(shell find tarantool-operator/api tarantool-operator/assets tarantool-operator/config tarantool-operator/controllers tarantool-operator/helm-charts -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum | awk '{print $$1}'); \
	if ! [ ${newhash} = ${oldhash} ]; then \
		echo "Operator changed, new tag:"; \
		echo ${newhash}; \
		echo ${oldhash} "(old hash)"; \
		echo ${newhash} > tarantool-operator/tag.sha; fi

op-build: op-hash ## Build docker image
	REPO=${OPREPO} VERSION=${OPVER}-$(file <${OPHASH}) \
	 make -C tarantool-operator build
	sed -i 's/golang:1.16/golang:1.17/' tarantool-operator/Dockerfile
	REPO=${OPREPO} VERSION=${OPVER}-$(file <${OPHASH}) \
	 make -C tarantool-operator docker-build

op-push: ## Push docker to repo (default needs credentials)
	docker push ${OPREPO}:${OPVER}-$(file <${OPHASH})

OPCHART := tarantool-operator/helm-charts/tarantool-operator

op-configure: 
	@echo "Configuring Tarantool Operator"
	@echo "Version: ${OPVER}-$(file <${OPHASH})"
	@echo "Docker repo: ${APP_DOCKER_URL}"
	@sed -e "s/@@VERSION@@/${OPVER}-$(file <${OPHASH})/g" skel/operator-values.yaml \
	| sed -e "s/@@APP_DOCKER_URL@@/${APP_DOCKER_URL}/" > ${OPCHART}/values.yaml

op-install: op-configure ## Helm install operator on Kubernetes
	helm install -n ${OPNS} operator ${OPCHART} \
		--create-namespace \
		--set image.repository=${OPREPO} \
		--set image.tag=${OPVER}-$(file <${OPHASH})

op-uninstall: ## Helm uninstall operator on Kubernetes
	-helm uninstall -n ${OPNS} operator

op-restart: op-uninstall op-install ## Helm restart operator

op-status: ## Show status of operator
	helm status -n ${OPNS} operator

op-logs: ## Show logs of operator
	@pods=`kubectl get pods --namespace ${OPNS} | awk '/^NAME/{next} {print $$1}'`; \
	for p in $$pods; do \
		echo "pod: \033[36m$$p\033[0m"; \
		kubectl logs $$p --namespace ${OPNS}; \
	done

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

logs: ## Show logs for all running APPs
	@for i in $(basename ${APPS}); do \
		echo "APP: \033[36m$$i\033[0m"; \
		pods=`kubectl get pods --namespace zenswarm-$$i | awk '/^NAME/{next} /^controller/{next} {print $$1}'`; \
		for p in $$pods; do \
			echo "pod: \033[36m$$p\033[0m"; \
			kubectl logs $$p --namespace zenswarm-$$i; \
		done; \
		echo $$pods; \
	done

uninstall-all: app-uninstall-a op-uninstall ## Uninstall all apps and operator
