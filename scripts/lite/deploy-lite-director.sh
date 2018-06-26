#!/bin/bash

main() {
	check_env

	echo ":::::::Setting up Bosh-Director"
  deploy_director

  echo ":::::::Setting up minikube"
	setup_minikube

	echo ":::::::Preaparing eirini and capi release"
  prepare_eirini_release
	prepeare_capi_release

	echo ":::::::Deploying CF and Eirini"
	deploy_cf_and_eirini

	echo ":::::::Setup CF environment"
	setup_cf_environment

	cat << EOF

      _/_/_/_/  _/_/_/  _/_/_/    _/_/_/  _/      _/  _/_/_/
     _/          _/    _/    _/    _/    _/_/    _/    _/
    _/_/_/      _/    _/_/_/      _/    _/  _/  _/    _/
   _/          _/    _/    _/    _/    _/    _/_/    _/
  _/_/_/_/  _/_/_/  _/    _/  _/_/_/  _/      _/  _/_/_/

  You are set and ready to use Eirini!

	We setup a CF Workspace for you:

	- Org: eirini
	- Space: dev

  All apps are going to end up on your minikube cluster in the "default" namespace.

  Have fun! :)
EOF
}

check_env() {
	${BOSH_DEPLOYMENT?"Environment variable BOSH_DEPLOYMENT not set"}
	${CF_DEPLOYMENT?"Environment variable CF_DEPLOYMENT not set"}
	${EIRINI_RELEASE?"Environment variable EIRINI_RELEASE not set"}
	${CAPI_RELEASE?"Environment variable CAPI_RELEASE not set"}
	${BOSH_DIRECTOR_ALIAS?"Environment variable BOSH_DIRECTOR_ALIAS not set"}
}

deploy_director() {
  bosh create-env "$BOSH_DEPLOYMENT"/bosh.yml \
    --state "$BOSH_DEPLOYMENT"/state.json \
    -o "$BOSH_DEPLOYMENT"/virtualbox/cpi.yml \
    -o "$BOSH_DEPLOYMENT"/virtualbox/outbound-network.yml \
    -o "$BOSH_DEPLOYMENT"/bosh-lite.yml \
    -o "$BOSH_DEPLOYMENT"/bosh-lite-runc.yml \
    -o "$BOSH_DEPLOYMENT"/jumpbox-user.yml \
    --vars-store "$BOSH_DEPLOYMENT"/creds.yml \
    -v director_name="Bosh Lite Director" \
    -v internal_ip=192.168.50.6 \
    -v internal_gw=192.168.50.1 \
    -v internal_cidr=192.168.50.0/24 \
    -v outbound_network_name=NatNetwork

  bosh -e 192.168.50.6 --ca-cert <(bosh int "$BOSH_DEPLOYMENT"/creds.yml --path /director_ssl/ca) alias-env "$BOSH_DIRECTOR_ALIAS"

  export BOSH_CLIENT=admin
  bosh_client_secret=$(bosh int "$BOSH_DEPLOYMENT"/creds.yml --path /admin_password)
  export BOSH_CLIENT_SECRET=$bosh_client_secret

  bosh -e "$BOSH_DIRECTOR_ALIAS" env
}

setup_minikube() {
  minikube start --host-only-cidr 192.168.50.1/24 --insecure-registry="10.244.0.142:8080"
}

prepare_eirini_release() {
	pushd "$EIRINI_RELEASE"
	git submodule update --init --recursive
  ./scripts/buildfs.sh
	bosh sync-blobs
	popd
}

prepeare_capi_release() {
	pushd "$CAPI_RELEASE"
	git submodule update --init --recursive
	bosh sync-blobs
	popd
}


deploy_cf_and_eirini() {
	bosh -e "$BOSH_DIRECTOR_ALIAS"  update-cloud-config -n $CF_DEPLOYMENT/iaas-support/bosh-lite/cloud-config.yml

  bosh int "$CF_DEPLOYMENT"/cf-deployment.yml \
     -o "$CF_DEPLOYMENT"/operations/experimental/enable-bpm.yml \
     -o "$CF_DEPLOYMENT"/operations/experimental/use-bosh-dns.yml \
     -o "$CF_DEPLOYMENT"/operations/bosh-lite.yml \
     -o "$EIRINI_RELEASE"/operations/eirini-bosh-operations.yml \
     -o "$EIRINI_RELEASE"/operations/dev-version.yml \
		 -o "$EIRINI_RELEASE"/operations/capi-dev-version.yml \
     --vars-store "$CF_DEPLOYMENT"/deployment-vars.yml \
     --var=k8s_flatten_cluster_config="$(kubectl config view --flatten=true)" \
     -v system_domain=bosh-lite.com \
     -v cc_api=https://api.bosh-lite.com \
     -v kube_namespace="default" \
     -v kube_endpoint="no-endpoint" \
     -v nats_ip=10.244.0.129 \
     -v registry_address="registry.bosh-lite.com:8089" \
     -v eirini_ip=10.244.0.142 \
     -v eirini_address="http://eirini.bosh-lite.com:8090" \
     -v eirini_local_path="$EIRINI_RELEASE" \
		 -v capi_local_path="$CAPI_RELEASE" > "$EIRINI_LITE"/manifest.yml

	STEMCELL_VERSION=$(bosh int "$EIRINI_LITE"/manifest.yml --path /stemcells/alias=default/version)

	bosh -e "$BOSH_DIRECTOR_ALIAS" upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent\?v\=$STEMCELL_VERSION

	bosh -e "$BOSH_DIRECTOR_ALIAS" deploy -d cf -n "$EIRINI_LITE"/manifest.yml
  verify_exit_code
}

setup_cf_environment(){
	cf api api.bosh-lite.com
	verify_exit_code

	cf_admin_pass=$(bosh int "$CF_DEPLOYMENT"/deployment-vars.yml --path /cf_admin_password)
	cf auth admin "$cf_admin_pass"
	verify_exit_code

  cf create-org eirini
	cf target -o eirini
	cf create-space dev
	cf target -s dev
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
