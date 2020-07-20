VERSION_SUFFIX ?= -$(OS)-$(TIME)
PYTEST_ARGS ?=
SERVICE ?= django
PARTITIONS ?= 4
CURRENT_SIGN_SETTING := $(shell git config commit.gpgSign)

_OS := $(shell python3 -c 'from sys import platform; print({"linux": "LNX", "darwin": "OSX"}.get(platform))')
_TIME := $(shell date +%s)
BS23_VERSION := $(shell git describe --tags)$(foreach OS,$(_OS),$(foreach TIME,$(_TIME),$(VERSION_SUFFIX)))

_pytest_env  = BS23_REGISTRY=$(BS23_REGISTRY)
_pytest_env += BS23_VERSION=$(BS23_VERSION)
_pytest_env += SCOUT_DISABLE=1


default: help
	@echo
	@echo "See                 ./docs/index.rst"
	@echo "or https://github.com/dynamicguy/rest_framework_simplejwt"
.PHONY: default

.PHONY: clean-pyc clean-build docs

acquire-sudo: ## Attempt to get credentials cached early on while the user is still looking in terminal
	sudo echo -n
.PHONY: acquire-sudo

clean-build: ## clean and build
	rm -fr build/
	rm -fr dist/
	rm -fr *.egg-info
.PHONY: clean-build

clean-pyc:  ## clean python compiled files
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
.PHONY: clean-pyc

lint: ## run linters
	tox -e lint
.PHONY: lint

lint-roll: ## fix lint errors
	isort --recursive rest_framework_simplejwt tests
	$(MAKE) lint
.PHONY: lint-roll


test: ## run tests with pytest
	pytest tests
.PHONY: test

test-all: ## run all tests with tox
	tox
.PHONY: test-all

build-docs: ## build docs
	sphinx-apidoc -o docs/ . \
		setup.py \
		*confest* \
		tests/* \
		rest_framework_simplejwt/token_blacklist/* \
		rest_framework_simplejwt/backends.py \
		rest_framework_simplejwt/compat.py \
		rest_framework_simplejwt/exceptions.py \
		rest_framework_simplejwt/settings.py \
		rest_framework_simplejwt/state.py
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(MAKE) -C docs doctest
.PHONY: build-docs

docs: build-docs ## build and open docs
	open docs/_build/html/index.html
.PHONY: docs

linux-docs: build-docs ## lint and build docs
	xdg-open docs/_build/html/index.html
.PHONY: linux-docs

release: clean ## clean and release
	git config commit.gpgSign true
	bumpversion $(bump)
	git push upstream && git push upstream --tags
	python setup.py sdist bdist_wheel
	twine upload dist/*
	git config commit.gpgSign "$(CURRENT_SIGN_SETTING)"
.PHONY: release

dist: clean ## create distribution
	python setup.py sdist bdist_wheel
	ls -l dist
.PHONY: clean

help: ## Show this message
	@echo 'usage: make [TARGETS...] [VARIABLES...]'
	@echo
	@echo VARIABLES:
	@sed -n '/[?]=/s/^/  /p' ${MAKEFILE_LIST}
	@echo
	@echo TARGETS:
	@sed -n 's/:.*[#]#/:#/p' ${MAKEFILE_LIST} | column -t -c 2 -s ':#' | sed 's/^/  /'
.PHONY: help

# I put this as the last line in the file because it confuses Emacs
# syntax highlighting and makes the remainder of the file difficult to
# edit.
escape_squotes = $(subst ','\'',$1)
