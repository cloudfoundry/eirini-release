#!/bin/bash

set -euo pipefail

kapp delete -y -a eirini
kapp delete -y -a wiremock
