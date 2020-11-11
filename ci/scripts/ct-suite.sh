#!/bin/bash

set -euo pipefail

cd /workspace/rabbitmq/deps/$project

! test -d ebin || touch ebin/*

trap 'catch $?' EXIT

catch() {
    if [ "$1" != "0" ]; then
        make ct-logs-archive && mv *-ct-logs-*.tar.xz /workspace/ct-logs/
    fi
}

SECONDARY_UMBRELLA_ARGS=""
if [[ "${SECONDARY_UMBRELLA_VERSION}" != "" ]]; then
    SECONDARY_UMBRELLA_ARGS="SECONDARY_UMBRELLA=${SECONDARY_UMBRELLA_VERSION}"
fi

buildevents cmd ${GITHUB_RUN_ID} ${GITHUB_RUN_ID}-${project} ct-${CT_SUITE} -- \
            make ct-${CT_SUITE} \
                 FULL= \
                 FAIL_FAST=1 \
                 SKIP_AS_ERROR=1 ${SECONDARY_UMBRELLA_ARGS}
