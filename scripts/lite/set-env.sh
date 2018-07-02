#!/bin/bash

set_env() {
  export BOSH_DEPLOYMENT_DIR=${BOSH_DEPLOYMENT_DIR:-"$EIRINI_LITE/bosh-deployment"}
	export CF_DEPLOYMENT=${CF_DEPLOYMENT:-"$EIRINI_LITE/cf-deployment"}
	export EIRINI_RELEASE=${EIRINI_RELEASE:-"$EIRINI_LITE/eirini-release"}
	export CAPI_RELEASE=${CAPI_RELEASE:-"$EIRINI_LITE/capi-release"}
	export BOSH_DIRECTOR_ALIAS=${BOSH_DIRECTOR_ALIAS:-"eirini-lite"}
}
