
all: validate build push
.PHONY: all

validate: validate-ui validate-comment validate-post validate-prometheus validate-alertmanager
.PHONY: validate
validate-ui:
	@cd $(PWD)/src/ui/ && hadolint Dockerfile
validate-comment:
	cd $(PWD)/src/comment/ && hadolint Dockerfile
validate-post:
	cd $(PWD)/src/post-py/ && hadolint Dockerfile
validate-prometheus:
	cd $(PWD)/monitoring/prometheus/ && hadolint Dockerfile
validate-alertmanager:
	cd $(PWD)/monitoring/alertmanager/ && hadolint Dockerfile

build: build-ui build-comment build-post build-prometheus build-alertmanager
.PHONY: build
build-ui:
	@cd $(PWD)/src/ui/ && bash docker_build.sh
build-comment:
	@cd $(PWD)/src/comment/ && bash docker_build.sh
build-post:
	@cd $(PWD)/src/post-py/ && bash docker_build.sh
build-prometheus:
	@cd $(PWD)/monitoring/prometheus/ && docker build -t $(USER_NAME)/prometheus .
build-alertmanager:
	@cd $(PWD)/monitoring/alertmanager/ && docker build -t $(USER_NAME)/alertmanager .

push: push-ui push-comment push-post push-prometheus push-alertmanager
.PHONY: push
push-ui:
	docker push $(USER_NAME)/ui
push-comment:
	docker push $(USER_NAME)/comment
push-post:
	docker push $(USER_NAME)/post
push-prometheus:
	docker push $(USER_NAME)/prometheus
push-alertmanager:
	docker push $(USER_NAME)/alertmanager

run: run-all
.PHONY: run
run-all:
	cd $(PWD)/docker/ && docker-compose up -d && docker-compose -f docker-compose-monitoring.yml up -d

stop: stop-all
.PHONY: stop
stop-all:
	cd $(PWD)/docker/ && docker-compose stop && docker-compose -f docker-compose-monitoring.yml stop

restart: restart-all
.PHONY: restart
restart-all:
	cd $(PWD)/docker/ && docker-compose restart && docker-compose -f docker-compose-monitoring.yml restart
