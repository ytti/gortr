EXTENSION ?= 
DIST_DIR ?= dist/
GOOS ?= linux
ARCH ?= $(shell uname -m)
BUILDINFOSDET ?= 

DOCKER_REPO   := cloudflare/
GORTR_NAME    := gortr
GORTR_VERSION := $(shell git describe --tags $(git rev-list --tags --max-count=1))
VERSION_PKG   := $(shell echo $(GORTR_VERSION) | sed 's/^v//g')
ARCH          := x86_64
LICENSE       := BSD-3
URL           := https://github.com/cloudflare/gortr
DESCRIPTION   := GoRTR: a RPKI-to-Router server
BUILDINFOS    :=  ($(shell date +%FT%T%z)$(BUILDINFOSDET))
LDFLAGS       := '-X main.version=$(GORTR_VERSION) -X main.buildinfos=$(BUILDINFOS)'

OUTPUT_GORTR := $(DIST_DIR)gortr-$(GORTR_VERSION)-$(GOOS)-$(ARCH)$(EXTENSION)

.PHONY: vet
vet:
	go vet cmd/gortr/gortr.go

.PHONY: prepare
prepare:
	mkdir -p $(DIST_DIR)

.PHONY: clean
clean:
	rm -rf $(DIST_DIR)

.PHONY: dist-key
dist-key: prepare
	cp cmd/gortr/cf.pub $(DIST_DIR)

.PHONY: build-gortr
build-gortr: prepare
	go build -ldflags $(LDFLAGS) -o $(OUTPUT_GORTR) cmd/gortr/gortr.go 

.PHONY: docker-gortr
docker-gortr:
	docker build -t $(DOCKER_REPO)$(GORTR_NAME):$(GORTR_VERSION) --build-arg LDFLAGS=$(LDFLAGS) -f Dockerfile.gortr .

.PHONY: package-deb-gortr
package-deb-gortr: prepare
	fpm -s dir -t deb -n $(GORTR_NAME) -v $(VERSION_PKG) \
        --description "$(DESCRIPTION)"  \
        --url "$(URL)" \
        --architecture $(ARCH) \
        --license "$(LICENSE)" \
       	--deb-no-default-config-files \
        --package $(DIST_DIR) \
        $(OUTPUT_GORTR)=/usr/bin/gortr \
        package/gortr.service=/lib/systemd/system/gortr.service \
        package/gortr.env=/etc/default/gortr \
        cmd/gortr/cf.pub=/usr/share/gortr/cf.pub

.PHONY: package-rpm-gortr
package-rpm-gortr: prepare
	fpm -s dir -t rpm -n $(GORTR_NAME) -v $(VERSION_PKG) \
        --description "$(DESCRIPTION)" \
        --url "$(URL)" \
        --architecture $(ARCH) \
        --license "$(LICENSE) "\
        --package $(DIST_DIR) \
        $(OUTPUT_GORTR)=/usr/bin/gortr \
        package/gortr.service=/lib/systemd/system/gortr.service \
        package/gortr.env=/etc/default/gortr \
        cmd/gortr/cf.pub=/usr/share/gortr/cf.pub