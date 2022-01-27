
##@ App development

# remove .app suffix from app name since completion often adds it
ext := $(suffix ${APP})
APP := $(if ${ext} = ".app",$(basename ${APP}),${APP})

app-check:
	$(if ${APP},,$(error "APP name undefined"))
	$(if $(wildcard ${APP}.app),,$(error "Cannot find app: ${APP}.app"))
	@echo "APP: \033[36m${APP}\033[0m"
	@echo "TAG:" $(file <${APP}.app/tag.sha)

app-hash:
	@oldhash=$(shell cat ${APP}.app/tag.sha); \
	newhash=$(shell find ${APP}.app/cartridge -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum | awk '{print $$1}'); \
	if ! [ $${newhash} = $${oldhash} ]; then \
		echo "APP changed, new tag:"; \
		echo $${newhash}; \
		echo $${oldhash} "(old hash)"; \
		echo $${newhash} > ${APP}.app/tag.sha; fi

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
	@rm -rf ${APP}.app/cartridge/.git ${APP}.app/cartridge/.cartridge
	@echo empty > ${APP}.app/tag.sha

app-create-chart:
	@mkdir -p ${APP}.app/chart
	@sed -e "s/@@APPNAME@@/${APP}/g" skel/chart/Chart.yaml \
	| sed -e "s/@@VERSION@@/${VERSION}/g" > ${APP}.app/chart/Chart.yaml
	@sed -e "s/@@APPNAME@@/${APP}/g" skel/chart/values.yaml \
	| sed -e "s/@@VERSION@@/${VERSION}/g" > ${APP}.app/chart/values.yaml
	@cp -ra skel/chart/templates ${APP}.app/chart/

app-create: app-check-empty app-create-cartridge app-create-chart app-hash ## Create a new app named APP

app-defaults: app-check app-create-chart app-hash ## Reset defaults in an existing app with APP
	@echo "Zenswarm reset app: ${APP}.app"

app-build: app-check app-hash ## Build Docker image from APP/cartridge
	@cartridge pack docker ${APP}.app/cartridge \
	 --tag dyne/zenswarm-${APP}:$(file <${APP}.app/tag.sha)
	@echo "Zenswarm build app: dyne/zenswarm-${APP}:" $(file <${APP}.app/tag.sha)

# sed -i -e "0,/ZENSWARM_TAG/{s/ZENSWARM_TAG.*/ZENSWARM_TAG='$(file <${APP}.app/tag.sha)'/}" \
#  ${APP}.app/cartridge/app/roles/custom.lua \
