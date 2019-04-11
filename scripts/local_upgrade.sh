#!/usr/bin/env bash

set -euxo pipefail

readonly DOCKER_USER=${1?Please provide a docker user}
readonly TAG=${2?Please provide a tag}
readonly VALUES_FILE=${3?Please provide a values yaml file}

sed -i "s/image: \(.*\):.*/image: \1:${TAG}/g" ${VALUES_FILE}

pushd src/code.cloudfoundry.org/eirini
./recipe/bin/build.sh ${DOCKER_USER} ${TAG}
./recipe/bin/push.sh ${DOCKER_USER} ${TAG}
popd

./docker/generate-docker-image.sh ${DOCKER_USER} ${TAG}
./docker/push-docker-image.sh ${DOCKER_USER} ${TAG}

pushd helm/cf
helm dependency update
popd
helm upgrade -f ${VALUES_FILE} scf helm/cf
