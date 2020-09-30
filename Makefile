PROJECT_NAME:=ez-opam
PORT:=9988
VERSION:=1.0
WWW_DIR:=share/$(PROJECT_NAME)/www

-include Makefile.config

.EXPORT_ALL_VARIABLES:

all: build website openapi

build: config
	dune build --profile release
	mkdir -p bin
	cp -f _build/default/src/api/opam_gui.exe bin/opam-gui

website:
	mkdir -p $(WWW_DIR)
	cp -f _build/default/src/ui/main_ui.bc.js $(WWW_DIR)/$(PROJECT_NAME)-ui.js
	rsync -ar static/* $(WWW_DIR)
	cp config/info.json $(WWW_DIR)
	sed -i 's/%{project_name}/$(PROJECT_NAME)/g' $(WWW_DIR)/index.html

clean:
	dune clean

install:
	dune install
	mkdir -p $$OPAM_SWITCH_PREFIX/share/$(PROJECT_NAME)
	cp -R www $$OPAM_SWITCH_PREFIX/share/$(PROJECT_NAME)/www

build-deps:
	opam install --deps-only .

Makefile.config: Makefile
	echo > Makefile.config
	echo PROJECT_NAME:=$(PROJECT_NAME) >> Makefile.config
	echo PORT:=$(PORT) >> Makefile.config
	echo VERSION:=$(VERSION) >> Makefile.config

src/config/pConfig.ml: Makefile.config
	echo "let project = {|$(PROJECT_NAME)|}" > src/config/pConfig.ml
	echo "let port = $(PORT)" >> src/config/pConfig.ml

.PHONY: config

config: config/info.json src/config/pConfig.ml

init: build-deps config

git-init:
	rm -rf .git
	git init

openapi: _build/default/src/api/openapi.exe
	@_build/default/src/api/openapi.exe --version $(VERSION) --title "$(PROJECT_NAME) API" --contact "$(CONTACT_EMAIL)" --servers "api" $(API_HOST) -o www/openapi.json
