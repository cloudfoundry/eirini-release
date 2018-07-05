#!/bin/bash

BASEDIR="$(cd $(dirname $0)/../../.. && pwd)"
export EIRINI_LITE=${EIRINI_LITE:-"$BASEDIR"}

source $EIRINI_LITE/eirini-release/scripts/lite/set-env.sh

main() {

  mkdir -p "$EIRINI_LITE"
	clone_repos

	set_env

	"$EIRINI_LITE"/eirini-release/scripts/lite/setup-eirini-environment.sh
}

clone_repos() {
  pushd $EIRINI_LITE
	  git clone https://github.com/cloudfoundry/bosh-deployment.git
	  git clone https://github.com/cloudfoundry/cf-deployment.git
		git clone -b develop --single-branch https://github.com/JulzDiverse/capi-release.git
	popd
}

main
