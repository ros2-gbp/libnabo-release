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
TESTED_FILE="docker_utilities.bash"
TESTED_FILE_PATH="src/function_library"

setup_file() {
  BATS_DOCKER_WORKDIR=$(pwd) && export BATS_DOCKER_WORKDIR
#  pwd >&3 && tree -L 1 -a -hug >&3
#  tree -L 2 -a '/' >&3
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
#    echo "executed once after finishing t-he last test"
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

@test "n2st::show_and_execute_docker › docker in docker › expect skip" {
  assert_exist "/.dockerenv"
  run n2st::show_and_execute_docker "--version"
  assert_output --regexp "\]".*"Skipping the execution of Docker command".*"docker".*"${DOCKER_CMD}".*
  assert_success
}

@test "n2st::show_and_execute_docker › mock docker command › expect pass" {
  local DOCKER_CMD="--version"
  mock_docker_command_exit_ok
  assert_exist "/.dockerenv"
  run n2st::show_and_execute_docker "${DOCKER_CMD}" true
  assert_success
  assert_output --regexp "\]".*"Execute command".*"docker".*"${DOCKER_CMD}".*
  assert_output --regexp "done\]".*"Command".*"docker".*"${DOCKER_CMD}".*"completed successfully and exited docker"
}

@test "n2st::show_and_execute_docker › mock docker command › expect pass (teamcity casses)" {
  local DOCKER_CMD="--version"
  local IS_TEAMCITY_RUN=true
  mock_docker_command_exit_ok
  assert_exist "/.dockerenv"
  run n2st::show_and_execute_docker "${DOCKER_CMD}" true
  assert_success
  assert_output --regexp "\]".*"Execute command".*"docker".*"${DOCKER_CMD}".*
  assert_output --regexp "\#\#teamcity\[message text='".*"\|\]".*"Command".*"docker".*"${DOCKER_CMD}".*"completed successfully and exited docker".*"' status='NORMAL'\]"
#  bats_print_run_env_variable
}

@test "n2st::show_and_execute_docker › mock docker command › expect fail (teamcity casses)" {
  local DOCKER_CMD="--version"
  local IS_TEAMCITY_RUN=true
  mock_docker_command_exit_error
  assert_exist "/.dockerenv"
  run n2st::show_and_execute_docker "${DOCKER_CMD}" true
  assert_success
  assert_output --regexp "\]".*"Execute command".*"docker".*"${DOCKER_CMD}".*
  assert_output --regexp "\#\#teamcity\[message text='".*"\|\]".*"Command".*"docker".*"${DOCKER_CMD}".*"exited with error \(DOCKER_EXIT_CODE=1\)\!".*"' errorDetails='1' status='ERROR'\]"
#  bats_print_run_env_variable
}

@test "n2st::show_and_execute_docker › mock docker command › expect fail" {
  local DOCKER_CMD="--version"
  mock_docker_command_exit_error
  assert_exist "/.dockerenv"
  run n2st::show_and_execute_docker "${DOCKER_CMD}" true
  assert_success
  assert_output --regexp "\]".*"Execute command".*"docker".*"${DOCKER_CMD}".*
  assert_output --regexp .*"\]".*"Command".*"docker".*"${DOCKER_CMD}".*"exited with error \(DOCKER_EXIT_CODE=1\)\!".*
#  bats_print_run_env_variable
}

@test "n2st::add_user_to_the_docker_group ok" {
  run n2st::add_user_to_the_docker_group "$(whoami)"
  assert_success
}

# ====legacy API support testing===================================================================
@test "(legacy API support testing) show_and_execute_docker › docker in docker › expect skip" {
  assert_exist "/.dockerenv"
  run show_and_execute_docker "--version"
  assert_output --regexp "\]".*"Skipping the execution of Docker command".*"docker".*"${DOCKER_CMD}".*
  assert_success
}

@test "(legacy API support testing) show_and_execute_docker › mock docker command › expect pass" {
  local DOCKER_CMD="--version"
  mock_docker_command_exit_ok
  assert_exist "/.dockerenv"
  run show_and_execute_docker "${DOCKER_CMD}" true
  assert_success
  assert_output --regexp "\]".*"Execute command".*"docker".*"${DOCKER_CMD}".*
  assert_output --regexp "done\]".*"Command".*"docker".*"${DOCKER_CMD}".*"completed successfully and exited docker"
}

@test "(legacy API support testing) add_user_to_the_docker_group ok" {
  run add_user_to_the_docker_group "$(whoami)"
  assert_success
}
