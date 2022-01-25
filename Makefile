include config.mk

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' build/cluster.mk
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' build/apps.mk

include build/cluster.mk
include build/apps.mk

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
