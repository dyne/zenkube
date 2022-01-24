##@ Cluster setup

op-download: SOURCE := https://github.com/tarantool/tarantool-operator
op-download: ## clone tarantool-operator from github
	if [ ! -r tarantool-operator ]; then git clone ${SOURCE}; \
	else cd tarantool-operator && git checkout . && git pull --rebase; fi

op-build: ## Build docker image
	REPO=${OPREPO} VERSION=${OPVER} \
	 make -C tarantool-operator build
	sed -i 's/golang:1.16/golang:1.17/' tarantool-operator/Dockerfile
	REPO=${OPREPO} VERSION=${OPVER} \
	 make -C tarantool-operator docker-build

op-push: ## Push docker to repo (default needs credentials)
	docker push ${OPREPO}:${OPVER}

op-install: OPCHART := tarantool-operator/helm-charts/tarantool-operator
op-install: ## Helm install operator on Kubernetes
	sed -e "s/@@VERSION@@/0.0.9-dyne/g" \
	skel/operator-values.yaml > ${OPCHART}/values.yaml
	helm install -n ${OPNS} operator ${OPCHART} \
		--create-namespace \
		--set image.repository=${OPREPO} \
		--set image.tag=${OPVER}

op-uninstall: ## Helm uninstall operator on Kubernetes
	helm uninstall -n ${OPNS} operator

op-restart: uninstall-kube install-kube ## Helm restart operator

op-status: ## Show status of operator
	helm status -n ${OPNS} operator

op-logs: ## Show logs of operator
	@pods=`kubectl get pods --namespace ${OPNS} | awk '/^NAME/{next} {print $$1}'`; \
	for p in $$pods; do \
		echo "pod: \033[36m$$p\033[0m"; \
		kubectl logs $$p --namespace ${OPNS}; \
	done

uninstall-all: # Helm uninstall all apps
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
