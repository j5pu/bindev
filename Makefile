.PHONY: build bump clean env tests upload verbose

SHELL := $(shell command -v bash)
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export BASH_ENV := $(DIR).envrc
basename := $(shell basename $(DIR))
svu := svu --strip-prefix
current := $(shell $(svu) current)
next := $(shell $(svu) next)
patch := $(shell $(svu) patch)
tag := git tag --quiet
version := $(shell [ $(current) = $(next) ] && echo $(patch) || echo $(next) )

build:
	@git commit -a -m 'pre-build' || true
	@git tag $(version)
	@python3.9 -m build  $(DIR)

bump:
	@echo $(version)
	@git push --quiet --tags

clean:
	@rm -rf $(DIR)build
	@rm -rf $(DIR)/dist
	@rm -rf $(DIR)/*.egg-info
	@bin/bats.sh --clean

env:
	@echo $(current)
	@echo $(next)
	@echo $(patch)
	@echo $(version)

install: upload
	@pip3.9 install --upgrade $(basename)

install-local:
	@pip3.9 install --force-reinstall dist/*.whl

tests: clean
	@bin/bats.sh --tests

upload: clean tests build bump clean build
	@twine upload dist/*

wheel:
	@pip3.9 install dist/*.whl

verbose: clean
	@bin/bats.sh --verbose

