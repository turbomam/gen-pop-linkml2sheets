PYTHON_VERSION ?= 3.9
CMD := poetry run
SRC_DIR := src
TESTS_DIR := tests

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.PHONY: help

format: ## rewrites code with black and isort
	$(CMD) black $(SRC_DIR) $(TESTS_DIR)
	$(CMD) isort $(SRC_DIR) $(TESTS_DIR)
.PHONY: format

lint-black: ## checks src and tests with mypy
	$(CMD) black --check --fast $(SRC_DIR) $(TESTS_DIR)
.PHONY: lint-black

lint-flake: ## checks src and tests with mypy
	$(CMD) flakeheaven lint $(SRC_DIR) $(TESTS_DIR)
.PHONY: lint-flake

lint-mypy: ## checks type annotation
	$(CMD) mypy $(SRC_DIR)
.PHONY: lint-mypy

lint: lint-black lint-flake lint-mypy ## runs all static analysis tools
.PHONY: lint

test: ## runs tests
	$(CMD) pytest --cov=src --cov-report html:tests/.coverage $(TESTS_DIR)
.PHONY: test

safety: ## tests third part packages against a database of known compromised ones
	poetry export --with dev --format=requirements.txt --without-hashes | poetry run safety check --stdin

qa: safety lint test ## for CI/CD. Runs all code quality tools
.PHONY: qa

qa-local: format qa ## for local development (before checking in). Formats code and runs qa
.PHONY: qa-local

RUN=poetry run

clean:
	rm -rf target
	mkdir -p target
	touch target/.gitkeep

# assumes user has curl or wget installed. curl --output-dir ?
#   or modify generate_and_populate_template to take a url for the source schema?
target/personinfo.yaml:
	#wget -P $(dir $@) https://raw.githubusercontent.com/linkml/linkml/main/examples/PersonSchema/personinfo.yaml
	curl -o $@ https://raw.githubusercontent.com/linkml/linkml/main/examples/PersonSchema/personinfo.yaml

target/usage_template.tsv: target/personinfo.yaml
	$(RUN) generate_and_populate_template \
		 --base-class slot_definition \
		 --columns-to-insert slot \
		 --columns-to-insert class \
		 --destination-template $@ \
		 --meta-model-excel-file target/meta.xlsx \
		 --meta-path https://raw.githubusercontent.com/linkml/linkml-model/main/linkml_model/model/schema/meta.yaml \
		 --source-schema-path $<

target/enum_template.tsv: target/personinfo.yaml
	$(RUN) generate_and_populate_template \
		 --base-class enum_definition \
		 --base-class permissible_value \
		 --columns-to-insert enum \
		 --columns-to-insert permissible_value \
		 --destination-template $@ \
		 --meta-model-excel-file target/meta.xlsx \
		 --meta-path https://raw.githubusercontent.com/linkml/linkml-model/main/linkml_model/model/schema/meta.yaml \
		 --source-schema-path $<

# # schema_definition template can't be populated at this point
# # so this template will be blank
target/schema_template.tsv: target/personinfo.yaml
	$(RUN) generate_and_populate_template \
		 --base-class schema_definition \
		 --columns-to-insert schema \
		 --destination-template $@ \
		 --meta-model-excel-file target/meta.xlsx \
		 --meta-path https://raw.githubusercontent.com/linkml/linkml-model/main/linkml_model/model/schema/meta.yaml \
		 --source-schema-path $<

target/prefix_template.tsv: target/personinfo.yaml
	$(RUN) generate_and_populate_template \
		 --base-class prefix \
		 --columns-to-insert prefix \
		 --destination-template $@ \
		 --meta-model-excel-file target/meta.xlsx \
		 --meta-path https://raw.githubusercontent.com/linkml/linkml-model/main/linkml_model/model/schema/meta.yaml \
		 --source-schema-path $<