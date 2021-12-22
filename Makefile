.PHONY: build bump clean env tests upload verbose

SHELL := $(shell command -v bash)
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export BASH_ENV := $(DIR).envrc
basename := $(shell basename $(DIR))
next := $(shell bin/semver next)

build:
	@git commit -a -m 'pre-build' || true
	@git tag $(next)
	@python3.9 -m build  $(DIR)

bump:
	@echo $(next)
	@git push --quiet --tags

clean:
	@rm -rf $(DIR)build
	@rm -rf $(DIR)/dist
	@rm -rf $(DIR)/*.egg-info
	@bin/bats.sh --clean

env:
	@echo $(next)

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

