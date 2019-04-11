#!/bin/bash

set -euo pipefail

readonly BASEDIR="$(cd $(dirname $0)/.. && pwd)"
readonly EIRINIDIR="$BASEDIR/src/code.cloudfoundry.org/eirini"
readonly DOCKERDIR="$BASEDIR/docker"
readonly DOCKER_USER=${1?"Please provide a docker user"}
readonly TAG=${2?"Please provide a tag"}

main(){
    push_docker_images
}

push_docker_images() {
  push_image ${DOCKER_USER}/opi
  push_image ${DOCKER_USER}/opi-init
  push_image ${DOCKER_USER}/secret-smuggler
}

push_image() {
  local image_name="$1"

  echo "Pushing $image_name docker image..."
  docker push "${image_name}:$TAG"
  verify_exit_code $? "Failed to push $image_name docker image"
  echo "$image_name docker image pushed!"
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
