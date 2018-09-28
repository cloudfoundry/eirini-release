#!/bin/bash

set -euo pipefail

BASEDIR="$(cd $(dirname $0)/.. && pwd)"

echo "package main" > $BASEDIR/src/code.cloudfoundry.org/eirini/launcher/buildpackapplifecycle/launcher/package.go

$BASEDIR/src/code.cloudfoundry.org/eirini/launcher/bin/build-eirinifs.sh

cp $BASEDIR/src/code.cloudfoundry.org/eirini/launcher/image/eirinifs.tar eirinifs.tar
