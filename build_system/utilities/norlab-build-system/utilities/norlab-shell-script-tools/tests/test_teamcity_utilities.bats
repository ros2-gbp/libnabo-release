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
  echo -e "\n[\033[1;31mERROR\033[0m] $0 path to bats-core helper library unreachable at \"${BATS_HELPER_PATH}\"!"
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi

# ====Setup========================================================================================
TESTED_FILE="teamcity_utilities.bash"
TESTED_FILE_PATH="src/function_library"

setup_file() {
  BATS_DOCKER_WORKDIR=$(pwd) && export BATS_DOCKER_WORKDIR
#  pwd >&3 && tree -L 1 -a -hug >&3
#  printenv >&3
}

setup() {
  source .env.project
  cd $TESTED_FILE_PATH || exit 1
  source ./$TESTED_FILE
}

# ====Teardown=====================================================================================

teardown() {
  bats_print_run_env_variable_on_error
}

#teardown_file() {
#    echo "executed once after finishing the last test"
#}

# ====Test casses==================================================================================

@test "sourcing $TESTED_FILE from bad cwd › expect fail" {
  cd "${BATS_DOCKER_WORKDIR}/src/"
  # Note:
  #  - "echo 'Y'" is for sending an keyboard input to the 'read' command which expect a single character
  #    run bash -c "echo 'Y' | source ./function_library/$TESTED_FILE"
  #  - Alt: Use the 'yes [n]' command which optionaly send n time
  run bash -c "yes 1 | source ./function_library/$TESTED_FILE"
  assert_failure 1
  assert_output --partial "'$TESTED_FILE' script must be sourced from"
}

@test "sourcing $TESTED_FILE from ok cwd › expect pass" {
  cd "${BATS_DOCKER_WORKDIR}/${TESTED_FILE_PATH}"
  run bash -c "PROJECT_GIT_NAME=$PROJECT_GIT_NAME && source ./$TESTED_FILE"
  assert_success
}

@test "n2st::set_is_teamcity_run_environment_variable ok" {
  fake_IS_TEAMCITY_RUN
  run n2st::set_is_teamcity_run_environment_variable
  assert_success
  n2st::set_is_teamcity_run_environment_variable
  assert_not_empty  "$IS_TEAMCITY_RUN"
}

# ----teamcity_service_msg_block-------------------------------------------------------------------
@test "n2st::teamcity_service_msg_block › open and close ok" {
  local TEST_MSG="Test message"

  assert_empty "$CURRENT_BLOCK_SERVICE_MSG"
  n2st::teamcity_service_msg_blockOpened "$TEST_MSG"
  assert_not_empty "$CURRENT_BLOCK_SERVICE_MSG"
  echo "Do something"
  n2st::teamcity_service_msg_blockClosed "$TEST_MSG"
  assert_empty "$CURRENT_BLOCK_SERVICE_MSG"
}

@test "n2st::teamcity_service_msg_blockOpened › expect fail" {
  local TEST_MSG="Test message"
  local "CURRENT_BLOCK_SERVICE_MSG"="$TEST_MSG"

  run n2st::teamcity_service_msg_blockOpened "$TEST_MSG"
  assert_failure
}

@test "n2st::teamcity_service_msg_blockClosed ok" {
  local TEST_MSG="Test message"
  local "CURRENT_BLOCK_SERVICE_MSG"="$TEST_MSG"

  n2st::teamcity_service_msg_blockClosed
  assert_empty "$CURRENT_BLOCK_SERVICE_MSG"
}

@test "n2st::teamcity_service_msg_blockOpened › output ok" {
  local TEST_MSG="Test message"
  local IS_TEAMCITY_RUN=false

  run n2st::teamcity_service_msg_blockOpened "$TEST_MSG"
  assert_output --partial "$TEST_MSG"
}

@test "n2st::teamcity_service_msg_blockOpened › output ok (teamcity casses)" {
  local TEST_MSG="Test message"
  local IS_TEAMCITY_RUN=true

  run n2st::teamcity_service_msg_blockOpened "$TEST_MSG"
  assert_output --regexp "\#\#teamcity\[blockOpened name='".*"\|\]".*"$TEST_MSG'\]"
}

@test "n2st::teamcity_service_msg_blockClosed › output ok (teamcity casses)" {
  local TEST_MSG="Test message"
  local "CURRENT_BLOCK_SERVICE_MSG"="$TEST_MSG"
  local IS_TEAMCITY_RUN=true

  run n2st::teamcity_service_msg_blockClosed
  assert_output --regexp "\#\#teamcity\[blockClosed name='".*"\|\]".*"$TEST_MSG'\]"
}

# ----teamcity_service_msg_compilation-------------------------------------------------------------
@test "n2st::teamcity_service_msg_compilation › open and close ok" {
  local TEST_MSG="Test message"

  assert_empty "$CURRENT_COMPILATION_SERVICE_MSG_COMPILER"
  n2st::teamcity_service_msg_compilationStarted "$TEST_MSG"
  assert_not_empty "$CURRENT_COMPILATION_SERVICE_MSG_COMPILER"
  echo "Do something"
  n2st::teamcity_service_msg_compilationFinished "$TEST_MSG"
  assert_empty "$CURRENT_COMPILATION_SERVICE_MSG_COMPILER"
}

@test "n2st::teamcity_service_msg_compilationStarted › expect fail" {
  local TEST_MSG="Test message"
  local "CURRENT_COMPILATION_SERVICE_MSG_COMPILER"="$TEST_MSG"

  run n2st::teamcity_service_msg_compilationStarted "$TEST_MSG"
  assert_failure
}

@test "n2st::teamcity_service_msg_compilationFinished ok" {
  local TEST_MSG="Test message"
  local "CURRENT_COMPILATION_SERVICE_MSG_COMPILER"="$TEST_MSG"

  n2st::teamcity_service_msg_compilationFinished
  assert_empty "$CURRENT_COMPILATION_SERVICE_MSG_COMPILER"
}

@test "n2st::teamcity_service_msg_compilationStarted › output ok" {
  local TEST_MSG="Test message"
  local IS_TEAMCITY_RUN=false

  run n2st::teamcity_service_msg_compilationStarted "$TEST_MSG"
  assert_output --partial "$TEST_MSG"
}

@test "n2st::teamcity_service_msg_compilationStarted › output ok (teamcity casses)" {
  local TEST_MSG="Test message"
  local IS_TEAMCITY_RUN=true

  run n2st::teamcity_service_msg_compilationStarted "$TEST_MSG"
  assert_output --regexp "\#\#teamcity\[compilationStarted compiler='".*"\|\]".*"$TEST_MSG'\]"
}

@test "n2st::teamcity_service_msg_compilationFinished › output ok (teamcity casses)" {
  local TEST_MSG="Test message"
  local "CURRENT_COMPILATION_SERVICE_MSG_COMPILER"="$TEST_MSG"
  local IS_TEAMCITY_RUN=true

  run n2st::teamcity_service_msg_compilationFinished
  assert_output --regexp "\#\#teamcity\[compilationFinished compiler='".*"\|\]".*"$TEST_MSG'\]"
}

# ====legacy API support testing===================================================================
@test "(legacy API support testing) set_is_teamcity_run_environment_varibale ok" {
  fake_IS_TEAMCITY_RUN
  run set_is_teamcity_run_environment_variable
  assert_success
  set_is_teamcity_run_environment_variable
  assert_not_empty  "$IS_TEAMCITY_RUN"
}

@test "(legacy API support testing) teamcity_service_msg_block › open and close ok" {
  local TEST_MSG="Test message"

  assert_empty "$CURRENT_BLOCK_SERVICE_MSG"
  teamcity_service_msg_blockOpened "$TEST_MSG"
  assert_not_empty "$CURRENT_BLOCK_SERVICE_MSG"
  echo "Do something"
  teamcity_service_msg_blockClosed "$TEST_MSG"
  assert_empty "$CURRENT_BLOCK_SERVICE_MSG"
}

@test "(legacy API support testing) teamcity_service_msg_compilation › open and close ok" {
  local TEST_MSG="Test message"

  assert_empty "$CURRENT_COMPILATION_SERVICE_MSG_COMPILER"
  teamcity_service_msg_compilationStarted "$TEST_MSG"
  assert_not_empty "$CURRENT_COMPILATION_SERVICE_MSG_COMPILER"
  echo "Do something"
  teamcity_service_msg_compilationFinished "$TEST_MSG"
  assert_empty "$CURRENT_COMPILATION_SERVICE_MSG_COMPILER"
}
