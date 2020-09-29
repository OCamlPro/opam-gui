PROJECT_NAME:=ez-opam
WEB_HOST:=http://localhost:8888
API_HOST:=http://localhost:8080
API_PORT:=8080
RLS_DIR:=www
CONTACT_EMAIL:=
VERSION:=1.0

-include Makefile.config

.EXPORT_ALL_VARIABLES:

all: build website api-server openapi

build: config
	dune build --profile release

website:
	mkdir -p www
	cp -f _build/default/src/ui/main_ui.bc.js www/$(PROJECT_NAME)-ui.js
	rsync -ar static/* www
	cp config/info.json www
	sed -i 's/%{project_name}/$(PROJECT_NAME)/g' www/index.html

api-server: _build/default/src/api/api_server.exe
	mkdir -p bin
	cp -f _build/default/src/api/api_server.exe bin/api-server

release:
	sudo cp -r www/* $(RLS_DIR)

clean:
	dune clean

install:
	dune install

build-deps:
	opam install --deps-only .

Makefile.config: Makefile
	echo > Makefile.config
	echo PROJECT_NAME:=$(PROJECT_NAME) >> Makefile.config
	echo WEB_HOST:=$(WEB_HOST) >> Makefile.config
	echo API_HOST:=$(API_HOST) >> Makefile.config
	echo API_PORT:=$(API_PORT) >> Makefile.config
	echo RLS_DIR:=$(RLS_DIR) >> Makefile.config
	echo CONTACT_EMAIL:=$(CONTACT_EMAIL) >> Makefile.config
	echo VERSION:=$(VERSION) >> Makefile.config

config/info.json: Makefile.config
	mkdir -p config
	echo "{\"apis\": [\"$(API_HOST)\"]}" > config/info.json
	echo "{\"port\": $(API_PORT)}" > config/api_config.json

src/config/pConfig.ml: Makefile.config
	echo "let project = {|$(PROJECT_NAME)|}" > src/config/pConfig.ml
	echo "let web_host = {|$(WEB_HOST)|}" >> src/config/pConfig.ml
	echo "let api_host = {|$(API_HOST)|}" >> src/config/pConfig.ml
	echo "let api_port = $(API_PORT)" >> src/config/pConfig.ml

.PHONY: config

config: config/info.json src/config/pConfig.ml

init: build-deps config

git-init:
	rm -rf .git
	git init

openapi: _build/default/src/api/openapi.exe
	@_build/default/src/api/openapi.exe --version $(VERSION) --title "$(PROJECT_NAME) API" --contact "$(CONTACT_EMAIL)" --servers "api" $(API_HOST) -o www/openapi.json
