SHELL=/bin/bash
UID=$(shell id -u)
export UID

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1)
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')
GIT_REV_ID=`(git describe --tags 2>|/dev/null) || (LC_ALL=C date +"%F-%X")`

.SHELLFLAGS = -o pipefail -c

.PHONY: ci
ci: check_version_mismatch up shards wait spec

up:
	docker-compose up -d

down:
	docker-compose down -v --remove-orphans

.PHONY: spec
spec:
	docker-compose exec crystal crystal spec $(O)

shards: shard.lock
shard.lock: shard.yml
	docker-compose exec crystal shards update

wait:
	docker-compose exec crystal ./wait-for pg:5432 -t 30
	docker-compose exec crystal ./wait-for my:3306 -t 30

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


