ifndef PYTHON_VERSION
	PYTHON_VERSION := $(shell python -c "import sys; print('%d.%d' % sys.version_info[0:2])")
endif

ifndef MODULE
	MODULE = plugins/modules/*.py
endif

ifndef TEST
	TEST = tests/unit/plugins/modules/*.py
endif

DEPRECATED = plugins/modules/_*.py
TEST_OMIT = $(DEPRECATED),tests/*

######################################################################################
# utility targets
######################################################################################

.PHONY: help
help:
	@echo "usage: make <target>"
	@echo ""
	@echo "target:"
	@echo "install-requirements ANSIBLE_VERSION=<version> 	install all requirements"
	@echo "install-ansible ANSIBLE_VERSION=<version>	install ansible: 2.9, 3, or 4"
	@echo "install-ansible-devel-branch			install ansible development branch"
	@echo "install-sanity-test-requirements		install python modules needed to \
	run sanity testing"
	@echo "install-unit-test-requirements 			install python modules needed \
	run unit testing"
	@echo "lint [MODULE]					lint module"         
	@echo "sanity-test [MODULE]				run sanity test on the collections"
	@echo "unit-test [TEST]				run unit test suite for the collection"
	@echo "clean						clean junk files"

.PHONY: clean
clean:
	@rm -rf tests/unit/plugins/modules/__pycache__
	@rm -rf tests/unit/plugins/modules/common/__pycache__
	@rm -rf collections/ansible_collections
	@rm -rf plugins/modules/__pycache__

######################################################################################
# installation targets
######################################################################################

.PHONY: install-requirements
install-requirements: install-ansible install-sanity-test-requirements \
		install-unit-test-requirements
	python -m pip install --upgrade pip

.PHONY: install-ansible
install-ansible:
	python -m pip install --upgrade pip
ifdef ANSIBLE_VERSION
	python -m pip install ansible==$(ANSIBLE_VERSION).*
else
	python -m pip install ansible
endif

.PHONY: install-ansible-devel-branch
install-ansible-devel-branch:
	python -m pip install --upgrade pip
	python -m pip install https://github.com/ansible/ansible/archive/devel.tar.gz \
	--disable-pip-version-check

.PHONY: install-sanity-test-requirements
install-sanity-test-requirements:
	python -m pip install -r tests/sanity/sanity.requirements

.PHONY: install-unit-test-requirements
install-unit-test-requirements:
	python -m pip install -r tests/unit/unit.requirements

######################################################################################
# testing targets
######################################################################################

.PHONY: lint
lint:
	flake8 --ignore=E402,W503 --max-line-length=160 --exclude $(DEPRECATED) $(MODULE)
	python -m pycodestyle --ignore=E402,W503 --max-line-length=160 --exclude $(DEPRECATED) \
		$(MODULE)

.PHONY: compile
compile:
	ansible-test sanity --test compile --python $(PYTHON_VERSION) $(MODULE)

.PHONY: sanity-test
sanity-test:
	ansible-test sanity -v --color yes --truncate 0 --python $(PYTHON_VERSION) \
		--exclude $(DEPRECATED) $(MODULE)

.PHONY: unit-test
unit-test:
	@if [ -d "tests/output/coverage" ]; then \
		ansible-test coverage erase; \
	fi
	ansible-test units -v --color yes --python $(PYTHON_VERSION) \
	--coverage $(TEST)
	
	ansible-test coverage report --omit $(TEST_OMIT) --include "$(MODULE)" --show-missing


