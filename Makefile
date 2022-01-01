.PHONY: clean tests build publish

SHELL := $(shell command -v bash)
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export BASH_ENV := $(DIR).envrc
basename := $(shell basename $(DIR))
next := $(shell bin/semver next)
tmp_build := $(shell mktemp -d)
tmp_publish := $(shell mktemp -d)

clean:
	@rm -rf $(DIR)build
	@rm -rf $(DIR)/dist
	@rm -rf $(DIR)/*.egg-info
	@bin/bats.sh --clean

tests: clean
	@bin/bats.sh --tests

build: tests
	@git commit -a -m "$(next): build" || true
	@python3.9 -m build -o $(tmp_build) $(DIR)

publish: build
	@git tag $(next)
	@git push --quiet
	@git push --quiet --tags
	@python3.9 -m build -o $(tmp_publish) $(DIR)
	@twine upload $(tmp_publish)/*
	@sleep 1
	@curl -sL -o /dev/null --head --fail https://pypi.org/manage/project/bindev/release/$(next)
	@PYTHONWARNINGS="ignore" python3 -m pip install -vvv --no-cache-dir --force-reinstall --upgrade --quiet $(basename)
	@python3 -m pip show bindev | awk '/^Version: / { print $2 }'

install-local-wheel-force: build
	@pip3.9 install --force-reinstall dist/*.whl

install-local-wheel: build
	@pip3.9 install dist/*.whl

verbose: clean
	@bin/bats.sh --verbose

