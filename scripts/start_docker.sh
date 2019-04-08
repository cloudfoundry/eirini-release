#! /bin/bash

set -e

WORKSPACE=$HOME/workspace/eirini-release
REPO=https://github.com/cloudfoundry-incubator/eirini-release
BRANCH=secure-stager


function ensure_exist() {
  dir=$1
  repo=$2
  branch=$3
  if [ ! -d $dir ]; then
      read -n 1 -p "$dir not found. Cloning it from $repo Continue [Y/n] ? " answer
      echo
      if [ "x$answer" == "xy" -o "x$answer" == "xY" ]; then
          git clone $repo $dir -b $branch --recursive
      fi
  fi
}

ensure_exist $WORKSPACE $REPO $BRANCH

# docker pull nimak/integration-tests
docker run --rm --privileged \
  -v ~/workspace/eirini-release:/eirini-release \
  -it nimak/integration-tests bash -l
