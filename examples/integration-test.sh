#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SCRIPTPATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

cd "${SCRIPTPATH}"
# shellcheck disable=SC2035,SC2045
for test_dir in $(ls -1 -d */);do
	echo "################################################################################"
	echo "${test_dir}"
	echo "################################################################################"
	cd "${SCRIPTPATH}/${test_dir}"
	if ! ./integration-test.sh; then
		exit 1
	fi
done
