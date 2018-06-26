#!/bin/bash

readonly BASEDIR="$(cd $(dirname $0)/../.. && pwd)"

main() {
  export EIRINI_LITE=${EIRINI_LITE:-"$HOME/workspace/eirini-lite"}

  mkdir -p "$EIRINI_LITE"
	clone_repos

	set_env

	$BASEDIR/scripts/lite/deploy-lite-director.sh
}

clone_repos() {
  pushd $EIRINI_LITE
	  git clone https://github.com/cloudfoundry/bosh-deployment.git
	  git clone https://github.com/cloudfoundry/cf-deployment.git
		#git clone -b develop --single-branch https://github.com/JulzDiverse/capi-release.git
	  git clone https://github.com/cloudfoundry/capi-release.git
	popd
}

set_env() {
  export BOSH_DEPLOYMENT=${BOSH_DEPLOYMENT:-"$EIRINI_LITE/bosh-deployment"}
	export CF_DEPLOYMENT=${CF_DEPLOYMENT:-"$EIRINI_LITE/cf-deployment"}
	export EIRINI_RELEASE=${EIRINI_RELEASE:-"$BASEDIR"}
	export CAPI_RELEASE=${CAPI_RELEASE:-"$EIRINI_LITE/capi-release"}
	export BOSH_DIRECTOR_ALIAS=${BOSH_DIRECTOR_ALIAS:-"eirini-lite"}
}

main
