#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

readonly TARGET_BRANCH=${1:-develop}
readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly SUBMODULE_PATH="$PROJECT_ROOT"/src/code.cloudfoundry.org/eirini

main(){
  sync-repo
  bump-submodule
  commit
  print-latest-commit
  prompt-push
}

sync-repo() {
  git pull origin "$TARGET_BRANCH"
  git submodule update --init --recursive "$SUBMODULE_PATH"
}

bump-submodule() {
  pushd "$SUBMODULE_PATH" || exit
    git fetch origin "$TARGET_BRANCH"
    git checkout "$TARGET_BRANCH"
  popd || exit
}

get-latest-commit() {
  pushd "$SUBMODULE_PATH" || exit
    git rev-list \
        --format=%n%Cgreen%B%Creset \
        --color=always \
        --max-count=1 \
        HEAD
  popd || exit
}

commit() {
  git add "$SUBMODULE_PATH"
  git duet-commit -m "Bump Eirini"
}

print-latest-commit() {
  local latest_commit_msg
  latest_commit_msg="$(get-latest-commit)"

  printf '\n\n'
  echo "This is the latest commit in Eirini:"
  echo "--------------------------------------"
  echo "${latest_commit_msg}"
  echo "--------------------------------------"
  printf '\n\n'
}

prompt-push() {
  read -r -p "Do you want to push to $TARGET_BRANCH in eirini-release? [y/N]" yn
  case $yn in
      [Yy] ) git push origin "$TARGET_BRANCH" ;;
      * ) echo 'Bailing out' ;;
  esac
}

main
