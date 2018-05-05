build:
	docker-compose build

build-oss:
	docker-compose build --build-arg USE_NGINX_PLUS_ARG=false

build-clean:
	docker-compose build --no-cache

build-clean-oss:
	docker-compose build --no-cache --build-arg USE_NGINX_PLUS_ARG=false

run-local:
	docker-compose up

stop:
	docker-compose down
