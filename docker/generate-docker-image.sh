#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERDIR="$BASEDIR/docker"
TAG=${1:-"latest"}

main(){
    echo "Creating Eirini docker images..."
    build_opi
    create_docker_images
    echo "All images created successfully"
}

build_opi(){
  GOPATH="$BASEDIR" GOOS=linux CGO_ENABLED=0 go build -a -o "$DOCKERDIR/opi/opi" code.cloudfoundry.org/eirini/cmd/opi
}

create_docker_images() {
  create_image "$DOCKERDIR"/opi eirini/opi
  create_image "$DOCKERDIR"/opi/init eirini/opi-init
  create_image "$DOCKERDIR"/registry/certs/smuggler eirini/secret-smuggler
  docker build -f  "$DOCKERDIR"/rootfs-patcher/Dockerfile -t "eirini/rootfs-patcher:${TAG}" "$BASEDIR"
  docker build -f  "$DOCKERDIR"/bits-waiter/Dockerfile -t "eirini/bits-waiter:${TAG}" "$BASEDIR"
}

create_image() {
  local path="$1"
  local image_name="$2"

  echo "Creating $image_name docker image..."
  pushd "$path" || exit
    if ! docker build . -t "${image_name}:$TAG"; then
      echo "Failed to create $image_name docker image"
      exit 1
    fi
  popd || exit
  echo "$image_name docker image created!"
}

main
