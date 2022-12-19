#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SCRIPTPATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

cd "${SCRIPTPATH}"
for test_dir in $(ls -1 -d */);do
	echo "################################################################################"
	echo "${test_dir}"
	echo "################################################################################"
	cd "${SCRIPTPATH}/${test_dir}"
	./integration-test.sh
done
