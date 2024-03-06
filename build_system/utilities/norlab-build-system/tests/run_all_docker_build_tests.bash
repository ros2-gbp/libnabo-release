#!/bin/bash
#
# Run all tests in directory
#
# Usage:
#   $ bash run_all_docker_build_tests.bash
#
#

_PATH_TO_SCRIPT="$(realpath "$0")"
SCRIPT_DIR_PATH="$(dirname "${_PATH_TO_SCRIPT}")"
TEST_DIR="$SCRIPT_DIR_PATH/tests_docker_build"

source "${SCRIPT_DIR_PATH}/../src/utility_scripts/nbs_run_all_test_and_dryrun_in_directory.bash" "${TEST_DIR}"

