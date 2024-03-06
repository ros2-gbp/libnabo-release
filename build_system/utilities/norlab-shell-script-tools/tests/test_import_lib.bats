#!/usr/bin/env bats
#
# Usage in docker container
#   $ REPO_ROOT=$(pwd) && RUN_TESTS_IN_DIR='tests'
#   $ docker run -it --rm -v "$REPO_ROOT:/code" bats/bats:latest "$RUN_TESTS_IN_DIR"
#
#   Note: "/code" is the working directory in the bats official image
#
# bats-core ref:
#   - https://bats-core.readthedocs.io/en/stable/tutorial.html
#   - https://bats-core.readthedocs.io/en/stable/writing-tests.html
#   - https://opensource.com/article/19/2/testing-bash-bats
#       ↳ https://github.com/dmlond/how_to_bats/blob/master/test/build.bats
#
# Helper library: 
#   - https://github.com/bats-core/bats-assert
#   - https://github.com/bats-core/bats-support
#   - https://github.com/bats-core/bats-file
#

BATS_HELPER_PATH=/usr/lib/bats
if [[ -d ${BATS_HELPER_PATH} ]]; then
  load "${BATS_HELPER_PATH}/bats-support/load"
  load "${BATS_HELPER_PATH}/bats-assert/load"
  load "${BATS_HELPER_PATH}/bats-file/load"
  load "${SRC_CODE_PATH}/${N2ST_BATS_TESTING_TOOLS_RELATIVE_PATH}/bats_helper_functions"
  #load "${BATS_HELPER_PATH}/bats-detik/load" # << Kubernetes support
else
  echo -e "\n[\033[1;31mERROR\033[0m] $0 path to bats-core helper library unreachable at \"${BATS_HELPER_PATH}\"!" 1>&2
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi

# ====Setup========================================================================================

TESTED_FILE="import_norlab_shell_script_tools_lib.bash"
TESTED_FILE_PATH="./"

# executed once before starting the first test (valide for all test in that file)
setup_file() {
  BATS_DOCKER_WORKDIR=$(pwd) && export BATS_DOCKER_WORKDIR

  ## Uncomment the following for debug, the ">&3" is for printing bats msg to stdin
#  pwd >&3 && tree -L 1 -a -hug >&3
#  printenv >&3
}

# executed before each test
setup() {
  cd "$TESTED_FILE_PATH" || exit 1
}

# ====Teardown=====================================================================================

# executed after each test
teardown() {
  bats_print_run_env_variable_on_error
}

## executed once after finishing the last test (valide for all test in that file)
#teardown_file() {
#}

# ====Test casses==================================================================================


@test "assess execute with \"source $TESTED_FILE\" › expect pass" {
  run source "$TESTED_FILE"
  assert_success
}

@test "${TESTED_FILE} › check if .env.n2st was properly sourced › expect pass" {
  # ....Pre-condition..............................................................................
  assert_empty ${PROJECT_PROMPT_NAME}
  assert_empty ${PROJECT_GIT_REMOTE_URL}
  assert_empty ${PROJECT_GIT_NAME}
  assert_empty ${PROJECT_SRC_NAME}
  assert_empty ${PROJECT_PATH}

  assert_empty ${N2ST_PROMPT_NAME}
  assert_empty ${N2ST_GIT_REMOTE_URL}
  assert_empty ${N2ST_GIT_NAME}
  assert_empty ${N2ST_SRC_NAME}
  assert_empty ${N2ST_PATH}

  # ....Import N2ST library........................................................................
  source "$TESTED_FILE"

  # ....Tests......................................................................................
  assert_equal "${PROJECT_PROMPT_NAME}" "N2ST"
  assert_regex "${PROJECT_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${PROJECT_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${PROJECT_SRC_NAME}" "norlab-shell-script-tools"
  assert_equal "${PROJECT_PATH}" "/code/norlab-shell-script-tools"

  assert_equal "${N2ST_PROMPT_NAME}" "N2ST"
  assert_regex "${N2ST_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${N2ST_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_SRC_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_PATH}" "/code/norlab-shell-script-tools"
}

@test "${TESTED_FILE} › validate the import function mechanism › expect pass" {
  # ....Import N2ST library........................................................................
  source "$TESTED_FILE"
  export GREETING="Hello NorLab"

  # ....Tests......................................................................................
  run n2st::good_morning_norlab
  assert_success
  assert_output --partial "${GREETING} ... there's nothing like the smell of a snow storm in the morning!"

  run n2st::norlab_splash
  assert_success

#  run n2st::set_which_architecture_and_os >&3
  run n2st::set_which_architecture_and_os
  assert_success
}


@test "${TESTED_FILE} › import from within a superproject › Env variables set ok" {
  TEST_N2ST_PATH="/code/norlab-shell-script-tools"
  SUPERPROJECT_NAME="dockerized-norlab-project-mock"
  SUPERPROJECT_PATH="/code/${SUPERPROJECT_NAME}"

  # ....Pre-condition..............................................................................
  assert_empty ${PROJECT_PROMPT_NAME}
  assert_empty ${PROJECT_GIT_REMOTE_URL}
  assert_empty ${PROJECT_GIT_NAME}
  assert_empty ${PROJECT_SRC_NAME}
  assert_empty ${PROJECT_PATH}

  assert_empty ${N2ST_PROMPT_NAME}
  assert_empty ${N2ST_GIT_REMOTE_URL}
  assert_empty ${N2ST_GIT_NAME}
  assert_empty ${N2ST_SRC_NAME}
  assert_empty ${N2ST_PATH}

  # ....Setup superproject.........................................................................
  assert_equal "$(pwd)" "$TEST_N2ST_PATH"
  cd ..
  assert_equal "$(pwd)" "/code"

  git clone "https://github.com/norlab-ulaval/${SUPERPROJECT_NAME}.git"
  assert_dir_exist "${SUPERPROJECT_PATH}"

#  # Visualise the testing directories
#  (echo && pwd && tree -L 2 -a) >&3

  # ....Import N2ST library........................................................................
  cd "$TEST_N2ST_PATH"
  source "$TESTED_FILE"

  # ....Tests......................................................................................
  # Env var prefixed PROJECT_ are set as expected
  assert_equal "${PROJECT_PROMPT_NAME}" "N2ST"
  assert_regex "${PROJECT_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${PROJECT_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${PROJECT_SRC_NAME}" "norlab-shell-script-tools"
  assert_equal "${PROJECT_PATH}" "/code/norlab-shell-script-tools"

  # Env var prefixed N2ST_ are still as expected
  assert_equal "${N2ST_PROMPT_NAME}" "N2ST"
  assert_regex "${N2ST_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${N2ST_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_SRC_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_PATH}" "/code/norlab-shell-script-tools"

  # ....Source .env.project........................................................................
  cd "${SUPERPROJECT_PATH}"
  assert_equal "$(pwd)" "${SUPERPROJECT_PATH}"

  set -o allexport && source "$N2ST_PATH/.env.project" && set +o allexport

#  # Visualise generated environment variables
#  (echo && printenv | grep -e PROJECT_ && echo) >&3

  # ....Tests......................................................................................
  # Env var prefixed PROJECT_ are set as expected
  assert_regex "${PROJECT_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/${SUPERPROJECT_NAME}"'(".git")?'
  assert_equal "${PROJECT_GIT_NAME}" "${SUPERPROJECT_NAME}"
  assert_equal "${PROJECT_PATH}" "${SUPERPROJECT_PATH}"
  assert_equal "${PROJECT_SRC_NAME}" "${SUPERPROJECT_NAME}"
  assert_equal "${PROJECT_SRC_NAME}" "dockerized-norlab-project-mock"

  # Env var prefixed N2ST_ are still as expected
  assert_equal "${N2ST_PROMPT_NAME}" "N2ST"
  assert_regex "${N2ST_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${N2ST_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_SRC_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_PATH}" "/code/norlab-shell-script-tools"

  # ....Teardown this test case ...................................................................
  # Delete cloned repository mock
  rm -rf "$SUPERPROJECT_PATH"
}

@test "assess execute with \"bash $TESTED_FILE\" › expect fail" {
  # ....Import N2ST library........................................................................
  run bash "$TESTED_FILE"

  # ....Tests......................................................................................
  assert_failure
  assert_output --regexp "[ERROR]".*"This script must be sourced i.e.:".*"source".*"$TESTED_FILE"
}

