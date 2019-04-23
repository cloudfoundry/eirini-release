#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERDIR="$BASEDIR/docker"
TAG=${1:-"latest"}

main(){
    echo "Creating Eirini docker images..."
    build_opi
    build_rootfs_patcher
    create_docker_images
    echo "All images created successfully"
}

build_opi(){
  GOPATH="$BASEDIR" GOOS=linux CGO_ENABLED=0 go build -a -o "$DOCKERDIR/opi/opi" code.cloudfoundry.org/eirini/cmd/opi
  verify_exit_code $? "Failed to build eirini"
}

build_rootfs_patcher() {
  GOPATH="$BASEDIR" GOOS=linux CGO_ENABLED=0 go build -a -o "$DOCKERDIR/rootfs-patcher/rootfs-patcher" code.cloudfoundry.org/eirini/cmd/rootfs-patcher
  verify_exit_code $? "Failed to build rootfs-patcher"
}

create_docker_images() {
  create_image "$DOCKERDIR"/opi eirini/opi
  create_image "$DOCKERDIR"/opi/init eirini/opi-init
  create_image "$DOCKERDIR"/registry/certs/smuggler eirini/secret-smuggler
  create_image "$DOCKERDIR"/rootfs-patcher eirini/rootfs-patcher
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
