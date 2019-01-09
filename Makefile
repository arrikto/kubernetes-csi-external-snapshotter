# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY: all csi-snapshotter clean test

REGISTRY_NAME=registry.dev.arr/csi
IMAGE_NAME=csi-snapshotter
IMAGE_VERSION=v1.0.1.arr1
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(IMAGE_VERSION)

REV=$(shell git describe --long --tags --match='v*' --dirty)

ifdef V
TESTARGS = -v -args -alsologtostderr -v 5
else
TESTARGS =
endif

GOPKG = github.com/kubernetes-csi/external-snapshotter

all: csi-snapshotter

csi-snapshotter: workspace
	mkdir -p bin
	GOPATH=${PWD}/workspace CGO_ENABLED=0 GOOS=linux \
		   go build -a -ldflags '-X main.version=$(REV) -extldflags "-static"' \
		   -o ./bin/csi-snapshotter ${GOPKG}/cmd/csi-snapshotter

workspace:
	mkdir -p workspace/src/$(dir ${GOPKG})
	ln -s ${PWD} workspace/src/${GOPKG}

clean:
	-rm -rf bin workspace

container: csi-snapshotter
	docker build -t $(IMAGE_TAG) .

push: container
	docker push $(IMAGE_TAG)

test:
	go test `go list ./... | grep -v 'vendor'` $(TESTARGS)
	go vet `go list ./... | grep -v vendor`
