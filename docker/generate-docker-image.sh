#!/bin/bash

BASEDIR="$(cd $(dirname $0)/.. && pwd)"
EIRINIDIR="$BASEDIR/src/code.cloudfoundry.org/eirini"
DOCKERDIR="$BASEDIR/kube-release/docker"
TAG=${1?"latest"}

main(){
    echo "Creating Eirini docker image..."
    build_opi
    create_eirinifs
    create_docker_images
    echo "Eirini docker image created"
}

build_opi(){
    GOPATH="$BASEDIR"
    GOOS=linux CGO_ENABLED=0 go build -a -o $DOCKERDIR/opi/opi code.cloudfoundry.org/eirini/cmd/opi
    verify_exit_code $? "Failed to build eirini"
  cp $DOCKERDIR/opi/opi $DOCKERDIR/registry/opi
}

create_eirinifs(){
  echo "package main" > $EIRINIDIR/launcher/buildpackapplifecycle/launcher/package.go
    $EIRINIDIR/launcher/bin/build-eirinifs.sh && \
    cp $EIRINIDIR/launcher/image/eirinifs.tar $DOCKERDIR/registry/

    verify_exit_code $? "Failed to create eirinifs.tar"
}

create_docker_images() {
  echo "Creating OPI docker image..."
    pushd $DOCKERDIR/opi
    docker build . -t "eirini/opi:$TAG"
    verify_exit_code $? "Failed to create opi docker image"
  popd
  echo "OPI docker image created!"

    echo "Creating Registry docker image..."
  pushd $DOCKERDIR/registry
  docker build . -t "eirini/registry:$TAG"
    verify_exit_code $? "Failed to create registry docker image"
  popd
    echo "Registry docker image created!"
}

verify_exit_code() {
    local exit_code=$1
    local error_msg=$2
    if [ "$exit_code" -ne 0 ]; then
        echo "$error_msg"
        exit 1
    fi
}

main
