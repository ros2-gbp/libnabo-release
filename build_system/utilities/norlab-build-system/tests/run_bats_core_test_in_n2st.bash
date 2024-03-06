#!/bin/bash
# =================================================================================================
# Execute 'norlab-build-system' repo shell script tests via 'norlab-shell-script-tools' library
#
# Note the script can be executed from anywhere as long as its inside the NBS repository
#
# Usage:
#   $ bash run_bats_core_test_in_n2st.bash ['<test-directory>[/<this-bats-test-file.bats>]' ['<image-distro>']]
#
# Arguments:
#   - ['<test-directory>']     The directory from which to start test, default to 'tests'
#   - ['<test-directory>/<this-bats-test-file.bats>']  A specific bats file to run, default will
#                                                      run all bats file in the test directory
#
# Globals: none
#
# =================================================================================================
PARAMS="$@"

if [[ -z $PARAMS ]]; then
  # Set to default bats tests directory if none specified
  PARAMS="tests/"
fi

function nbs::run_n2st_testsing_tools(){
  local TMP_CWD
  TMP_CWD=$(pwd)

  # ....Project root logic.........................................................................
  NBS_PATH=$(git rev-parse --show-toplevel)
  N2ST_PATH=${N2ST_PATH:-"./utilities/norlab-shell-script-tools"}

  # ....Execute N2ST run_bats_tests_in_docker.bash.................................................
  cd "$NBS_PATH"

  # shellcheck disable=SC2086
  bash "${N2ST_PATH}/tests/bats_testing_tools/run_bats_tests_in_docker.bash" $PARAMS

  # ....Teardown...................................................................................
  cd "$TMP_CWD"
  }

nbs::run_n2st_testsing_tools
