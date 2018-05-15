#!/bin/bash

set -euo pipefail

BASEDIR="$(cd $(dirname $0)/.. && pwd)"

echo "package main" > $BASEDIR/src/github.com/julz/cube/launcher/buildpackapplifecycle/launcher/package.go

$BASEDIR/src/github.com/julz/cube/launcher/bin/build-cubefs.sh

bosh add-blob $BASEDIR/src/github.com/julz/cube/launcher/image/cubefs.tar cubefs/cubefs.tar
