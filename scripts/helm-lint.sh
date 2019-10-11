#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
LIGHT_RED='\033[1;31m'
YELLOW='\033[0;93m'
NOCOLOR='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PROJECT_ROOT

pushd $PROJECT_ROOT/helm/cf || exit
helm dep update
popd || exit

exit_code=0
for filename in $PROJECT_ROOT/sample-configs/*; do
  if helm lint $PROJECT_ROOT/helm/cf --values "$filename"; then
    echo -e "${GREEN} PASS - ${YELLOW} $(basename "$filename") ${NOCOLOR}"
  else
    echo -e "${RED} FAIL - ${LIGHT_RED} $(basename "$filename") ${NOCOLOR}"
    exit_code=1
  fi
done

exit $exit_code
