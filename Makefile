SHELL=/bin/bash
UID=$(shell id -u)
export UID

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1)
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')
GIT_REV_ID=`(git describe --tags 2>|/dev/null) || (LC_ALL=C date +"%F-%X")`

.SHELLFLAGS = -o pipefail -c

ci: check_version_mismatch docker-up shards spec

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down -v --remove-orphans

shards:
	docker-compose exec test shards update

DEBUG=
VERBOSE=-v
FAIL_FAST=--fail-fast
WARNING=--warnings none

.PHONY : spec
spec:
	docker-compose exec test crystal spec $(VERBOSE) $(FAIL_FAST) $(WARNING)

.PHONY : check_version_mismatch
check_version_mismatch: shard.yml README.md
	diff -w -c <(grep version: README.md | head -1) <(grep ^version: shard.yml)

.PHONY : version
version:
	@if [ "$(VERSION)" = "" ]; then \
	  echo "ERROR: specify VERSION as bellow. (current: $(CURRENT_VERSION))";\
	  echo "  make version VERSION=$(GUESSED_VERSION)";\
	else \
	  sed -i -e 's/^version: .*/version: $(VERSION)/' shard.yml ;\
	  sed -i -e 's/^    version: [0-9]\+\.[0-9]\+\.[0-9]\+/    version: $(VERSION)/' README.md ;\
	  echo git commit -a -m "'$(COMMIT_MESSAGE)'" ;\
	  git commit -a -m 'version: $(VERSION)' ;\
	  git tag "v$(VERSION)" ;\
	fi

.PHONY : bump
bump:
	make version VERSION=$(GUESSED_VERSION) -s


.PHONY : backup
backup:
	@test -d backup
	tar zcf backup/pon.cr-$(GIT_REV_ID).tar.gz .git


