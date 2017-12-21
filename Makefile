#
# Placeholder makefile so "debuild" can be gently persuaded to work
#

REPORT_DIR = reports
COVERAGE_REPORT_DIR = $(REPORT_DIR)/coverage
TESTS_REPORT_DIR = $(REPORT_DIR)/tests

# Elaborate mechanism just to get the correct syntax for the pytest markers param
_FIRST_TAG := $(firstword $(OMITTED_TAGS))
PYTEST_TAGS_EXPR := $(foreach tag, $(OMITTED_TAGS), $(if $(filter $(tag), $(_FIRST_TAG)),not $(tag),and not $(tag)))

ifeq ($(PYTEST_TAGS_EXPR), )
	PYTEST_TAGS_FLAG :=
else
	PYTEST_TAGS_FLAG := -m "$(strip $(PYTEST_TAGS_EXPR))"
endif
BEHAVE_TAGS_FLAG := $(join $(addprefix --tags=-,$(OMITTED_TAGS)), $(space))


.PHONY: kano-keys-pressed kano-splash kano-launcher kano-logging kano kano-networking kano-python parson check test

all: kano-keys-pressed kano-splash kano-launcher kano kano-networking kano-python parson

kano-keys-pressed:
	cd kano-keys-pressed && make

kano-splash: kano-logging
	cd kano-splash && make

kano-launcher: kano-logging
	cd kano-launcher && make

kano-logging:
	cd kano-logging && make

kano: kano-python
	cd libs/kano && LOCAL_BUILD=1 make
	cd libs/kano && LOCAL_BUILD=1 make debug

kano-networking:
	cd libs/kano-networking && make
	cd libs/kano-networking && make debug

kano-python:
	cd libs/kano-python && make
	cd libs/kano-python && make debug

parson:
	cd libs/parson && make
	cd libs/parson && make debug

#
# Run the tests
#
# Requirements:
#     - pytest
#     - behave
#     - pytest-cov
#
check:
	# Refresh the reports directory
	rm -rf $(REPORT_DIR)
	mkdir -p $(REPORT_DIR)
	mkdir -p $(COVERAGE_REPORT_DIR)
	mkdir -p $(TESTS_REPORT_DIR)
	# Run the tests
	-coverage run --module pytest $(PYTEST_TAGS_FLAG) --junitxml=$(TESTS_REPORT_DIR)/pytest_results.xml
	-coverage run --append --module behave $(BEHAVE_TAGS_FLAG) --junit --junit-directory=$(TESTS_REPORT_DIR)
	# Generate reports
	coverage xml
	coverage html
	coverage-badge -o $(COVERAGE_REPORT_DIR)/kano-toolset-coverage.svg

test: check
