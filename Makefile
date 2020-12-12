ifneq (,)
.error This Makefile requires GNU Make.
endif


# -------------------------------------------------------------------------------------------------
# Docker configuration
# -------------------------------------------------------------------------------------------------

IMAGE = devilbox/nginx-stable
TAG = latest


# -------------------------------------------------------------------------------------------------
#  Default Target
# -------------------------------------------------------------------------------------------------

help:
	@echo "lint                      Lint project files and repository"
	@echo "build                     Build Docker image"
	@echo "rebuild                   Build Docker image without cache"
	@echo "test                      Test built Docker image"
	@echo "update-readme             Update README.md with PHP modules"
	@echo "tag [TAG=...]             Retag Docker image"
	@echo "login USER=... PASS=...   Login to Docker hub"
	@echo "push [TAG=...]            Push Docker image to Docker hub"


# -------------------------------------------------------------------------------------------------
#  Lint Targets
# -------------------------------------------------------------------------------------------------

lint: lint-workflow

lint-workflow:
	@\
	GIT_CURR_MAJOR="$$( git tag | sort -V | tail -1 | sed 's|\.[0-9]*$$||g' )"; \
	GIT_CURR_MINOR="$$( git tag | sort -V | tail -1 | sed 's|^[0-9]*\.||g' )"; \
	GIT_NEXT_TAG="$${GIT_CURR_MAJOR}.$$(( GIT_CURR_MINOR + 1 ))"; \
	if ! grep 'refs:' -A 100 .github/workflows/nightly.yml \
		| grep  "          - '$${GIT_NEXT_TAG}'" >/dev/null; then \
		echo "[ERR] New Tag required in .github/workflows/nightly.yml: $${GIT_NEXT_TAG}"; \
		exit 1; \
	else \
		echo "[OK] Git Tag present in .github/workflows/nightly.yml: $${GIT_NEXT_TAG}"; \
	fi


# -------------------------------------------------------------------------------------------------
#  Build Targets
# -------------------------------------------------------------------------------------------------

build: pull-base-image
	docker build -t $(IMAGE) .
	./build/gen-readme.sh $(IMAGE)

rebuild: pull-base-image
	docker build --no-cache -t $(IMAGE) .
	./build/gen-readme.sh $(IMAGE)


# -------------------------------------------------------------------------------------------------
#  Test Targets
# -------------------------------------------------------------------------------------------------

test:
	.ci/start-ci.sh $(IMAGE) $(ARG)


# -------------------------------------------------------------------------------------------------
#  Deploy Targets
# -------------------------------------------------------------------------------------------------

tag:
	docker tag $(IMAGE) $(IMAGE):$(TAG)

login:
	yes | docker login --username $(USER) --password $(PASS)

push:
	@$(MAKE) tag TAG=$(TAG)
	docker push $(IMAGE):$(TAG)


# -------------------------------------------------------------------------------------------------
#  Helper Targets
# -------------------------------------------------------------------------------------------------

enter:
	docker run --rm --name $(subst /,-,$(IMAGE)) -it --entrypoint=bash $(ARG) $(IMAGE)

pull-base-image:
	@docker pull $(shell grep FROM Dockerfile | sed 's/^FROM\s*//g';)
