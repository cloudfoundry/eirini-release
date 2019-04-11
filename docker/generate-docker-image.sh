#!/bin/bash

set -euo pipefail

readonly BASEDIR="$(cd $(dirname $0)/.. && pwd)"
readonly EIRINIDIR="$BASEDIR/src/code.cloudfoundry.org/eirini"
readonly DOCKERDIR="$BASEDIR/docker"
readonly DOCKER_USER=${1?"Please provide a docker user"}
readonly TAG=${2?"Please provide a tag"}

main(){
    echo "Creating Eirini docker images..."
    build_opi
    create_docker_images
    echo "All images created successfully"
}

build_opi(){
    GOPATH="$BASEDIR"
    GOOS=linux CGO_ENABLED=0 go build -a -o $DOCKERDIR/opi/opi code.cloudfoundry.org/eirini/cmd/opi
    verify_exit_code $? "Failed to build eirini"
  cp $DOCKERDIR/opi/opi $DOCKERDIR/registry/opi
}

create_docker_images() {
  create_image "$DOCKERDIR"/opi ${DOCKER_USER}/opi
  create_image "$DOCKERDIR"/opi/init ${DOCKER_USER}/opi-init
  create_image "$DOCKERDIR"/registry/certs/smuggler ${DOCKER_USER}/secret-smuggler
}

create_image() {
  local path="$1"
  local image_name="$2"

  echo "Creating $image_name docker image..."
  pushd "$path" || exit
    docker build . -t "${image_name}:$TAG"
    verify_exit_code $? "Failed to create $image_name docker image"
  popd || exit
  echo "$image_name docker image created!"
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
