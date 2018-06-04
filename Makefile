build:
	docker-compose build

build-oss:
	docker-compose build --build-arg USE_NGINX_PLUS_ARG=false

build-clean:
	docker-compose build --no-cache

build-clean-oss:
	docker-compose build --no-cache --build-arg USE_NGINX_PLUS_ARG=false

run-fabric_local:
	docker-compose up --file fabric_docker-compose-local.yaml

stop:
	docker-compose down
