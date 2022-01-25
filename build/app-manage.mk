
##@ App management

app-push: APP_HASH := $(file <${APP}.app/tag.sha)
app-push: app-check app-hash ## Push the Docker image of APP
	docker push ${APP_DOCKER_URL}/zenswarm-${APP}:${APP_HASH}

app-install: APP_HASH := $(file <${APP}.app/tag.sha)
app-install: app-check ## Install the Helm APP/chart in namespace zenswarm-APP
	@sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
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
	@sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm upgrade -n zenswarm-${APP} @{APP} ${APP}.app/chart \
	--set image.tag=${APP_HASH} --set imagePullPolicy=Always \
	--recreate-pods

app-upgrade-f: APP_HASH := $(file <${APP}.app/tag.sha)
app-upgrade-f: app-check
	@sed -i -e "s/  tag:.*/  tag: ${APP_HASH}/" ${APP}.app/chart/values.yaml
	helm upgrade -n zenswarm-${APP} ${APP} ${APP}.app/chart \
	--set image.tag=${APP_HASH} --set imagePullPolicy=Always --create-namespace \
	--recreate-pods

app-status: app-check ## Check the status of installed APP
	helm status -n zenswarm-${APP} ${APP}

app-uninstall: ## Uninstall the APP
	-helm uninstall -n zenswarm-${APP} ${APP}

app-uninstall-f: ## Force uninstall the APP (--no-hooks)
	helm uninstall -n zenswarm-${APP} ${APP} --no-hooks

app-uninstall-a: ## Uninstall all the apps
	-@for i in $(basename ${APPS}); do \
		echo "Uninstall APP: \033[36m$$i\033[0m"; \
		helm uninstall -n zenswarm-$${i} $${i}; \
	done
