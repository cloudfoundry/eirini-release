#!/bin/bash

set -euo pipefail

BASEDIR="$(cd $(dirname $0)/.. && pwd)"

echo "package main" > $BASEDIR/src/github.com/cloudfoundry-incubator/eirini/launcher/buildpackapplifecycle/launcher/package.go

$BASEDIR/src/github.com/cloudfoundry-incubator/eirini/launcher/bin/build-cubefs.sh

bosh add-blob $BASEDIR/src/github.com/cloudfoundry-incubator/eirini/launcher/image/eirinifs.tar eirinifs/eirinifs.tar
