DUCKDB_VERSION?=0.10.0
ALPINE_VERSION?=3.19
REPOSITORY?=fgrehm/libduckdb

.PHONY: alpine
alpine:
	docker build \
		--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
		--build-arg DUCKDB_VERSION="$(DUCKDB_VERSION)" \
		-t $(REPOSITORY):$(DUCKDB_VERSION)-alpine$(ALPINE_VERSION) \
		-f Dockerfile.alpine \
		.

.PHONY: scratch
scratch:
	docker build \
		--build-arg DUCKDB_VERSION="$(DUCKDB_VERSION)" \
		-t $(REPOSITORY):$(DUCKDB_VERSION) \
		-f Dockerfile.scratch \
		.

.PHONY: test-alpine
test-alpine: alpine
	docker build \
		--build-arg REPOSITORY="$(REPOSITORY)" \
		--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
		--build-arg DUCKDB_VERSION="$(DUCKDB_VERSION)" \
		-t $(REPOSITORY):$(DUCKDB_VERSION)-alpine$(ALPINE_VERSION)-test \
		-f tests/Dockerfile.alpine \
		.
	docker run -ti --rm $(REPOSITORY):$(DUCKDB_VERSION)-alpine$(ALPINE_VERSION)-test ruby test.rb

.PHONY: test-slim
test-slim: scratch
	docker build \
		--build-arg REPOSITORY="$(REPOSITORY)" \
		--build-arg DUCKDB_VERSION="$(DUCKDB_VERSION)" \
		-t $(REPOSITORY):$(DUCKDB_VERSION)-slim-test \
		-f tests/Dockerfile.slim \
		.
	docker run -ti --rm $(REPOSITORY):$(DUCKDB_VERSION)-slim-test ruby test.rb
