#!/bin/bash

set -euo pipefail
set -x
IFS=$'\n\t'

GREEN='\033[0;92m'
NORMAL='\033[0m'

main(){
  while read -r _ _ remote_ref _
  do
  if [[ "$remote_ref" =~ .*/develop$ ]]; then
      check-ci
  fi
  done
}

check-ci(){
  if curl -s https://ci.eirini.cf-app.com/api/v1/teams/main/pipelines/ci/jobs | grep -Eq "failed|error"; then
    echo -e "Funny message: pipeline is $GREEN red.$NORMAL \\n"
    echo "Please fix it before pushing"
    prompt-push
  fi
  echo "CI is green"
}

prompt-push(){
  read -r -p "Do you want to push to $TARGET_BRANCH in eirini-release? [y/N]" yn
  case $yn in
      [Yy] ) exit 0 ;;
      * ) echo 'Bailing out'; exit 1 ;;
  esac
}

main
exit 1
