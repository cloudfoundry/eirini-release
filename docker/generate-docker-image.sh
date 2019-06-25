#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERDIR="$BASEDIR/docker"
TAG=${1:-"latest"}

main(){
  echo "Creating Eirini docker images..."
  create_image "$DOCKERDIR"/opi/init eirini/opi-init
  create_image "$DOCKERDIR"/registry/certs/smuggler eirini/secret-smuggler
  docker build -f  "$DOCKERDIR"/opi/Dockerfile -t "eirini/opi:${TAG}" "$BASEDIR"
  docker build -f  "$DOCKERDIR"/rootfs-patcher/Dockerfile -t "eirini/rootfs-patcher:${TAG}" "$BASEDIR"
  docker build -f  "$DOCKERDIR"/bits-waiter/Dockerfile -t "eirini/bits-waiter:${TAG}" "$BASEDIR"

  echo "All images created successfully"
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
