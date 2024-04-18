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

TESTED_FILE="nbs_execute_compose_over_build_matrix.bash"
TESTED_FILE_PATH="./src/utility_scripts/"

# executed once before starting the first test (valide for all test in that file)
setup_file() {
  BATS_DOCKER_WORKDIR=$(pwd) && export BATS_DOCKER_WORKDIR

  ## Uncomment the following for debug, the ">&3" is for printing bats msg to stdin
#  pwd >&3 && tree -L 1 -a -hug >&3
#  printenv >&3
}

# executed before each test
setup() {
  set -o allexport
  source "${SRC_CODE_PATH}"/build_system_templates/.env
  set +o allexport

  cd "$TESTED_FILE_PATH" || exit 1
}

# ====Teardown=====================================================================================

## executed after each test
#teardown() {
#  bats_print_run_env_variable_on_error
#}

## executed once after finishing the last test (valide for all test in that file)
#teardown_file() {
#}

# ====Test casses==================================================================================
function setup_dotenv_build_matrix_dependencies() {
  DOTENV_BUILD_MATRIX="${SRC_CODE_PATH}"/build_system_templates/.env.build_matrix.dependencies.template
  DOTENV_BUILD_MATRIX_NAME=$( basename "${DOTENV_BUILD_MATRIX}" )
}


function setup_dotenv_build_matrix_superproject() {
  DOTENV_BUILD_MATRIX="${SRC_CODE_PATH}"/build_system_templates/.env.build_matrix.project.template
  DOTENV_BUILD_MATRIX_NAME=$( basename "${DOTENV_BUILD_MATRIX}" )
}

@test "executing $TESTED_FILE from bad cwd › expect fail" {
  cd "${BATS_DOCKER_WORKDIR}/src/"
  run bash ./utility_scripts/$TESTED_FILE
  assert_failure 1
  assert_output --regexp  .*"\[".*"ERROR".*"\]".*"'nbs_execute_compose_over_build_matrix.bash' script must be executed from the 'norlab-build-system/src/utility_scripts/' directory!"
}

@test "sourcing $TESTED_FILE whitout importing NBS › expect fail" {

  setup_dotenv_build_matrix_dependencies

  assert_not_equal "$NBS_IMPORTED" true

  run source "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --fail-fast -- build

  assert_failure 1
  assert_output --regexp  .*"\[".*"ERROR".*"\]".*"You need to execute".*"import_norlab_build_system_lib.bash".*"before sourcing".*"nbs_execute_compose_over_build_matrix.bash".*"otherwise run it with bash."
}

@test "sourcing $TESTED_FILE after importing NBS › expect fail" {

  setup_dotenv_build_matrix_dependencies

  assert_not_equal "$NBS_IMPORTED" true

  cd "${SRC_CODE_PATH}"
  source import_norlab_build_system_lib.bash

  assert_equal "$NBS_IMPORTED" true

  cd "$TESTED_FILE_PATH"
  run source "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --fail-fast -- build

  assert_success
  refute_output --regexp  .*"\[".*"ERROR".*"\]".*"You need to execute".*"import_norlab_build_system_lib.bash".*"before sourcing".*"nbs_execute_compose_over_build_matrix.bash".*"otherwise run it with bash."
}


# ....Prompt related tests.........................................................................
@test "${TESTED_FILE} › NBS console prompt name is not overiten by superproject dotenv PROJECT_PROMPT_NAME › expect pass" {

  setup_dotenv_build_matrix_dependencies

  run bash "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --fail-fast -- build
  assert_success
  assert_output --regexp .*"Starting".*"${TESTED_FILE}".*"\[NBS\]".*"Build images specified in".*"\[NBS\]".*"Environment variables"
  assert_output --regexp "\[NBS done\]".*"FINAL › Build matrix completed with command".*"Completed".*"${TESTED_FILE}".*
}

# ....Dotenv related...............................................................................
@test "${TESTED_FILE} › env var from dotenv file exported › expect pass" {

  setup_dotenv_build_matrix_dependencies

  run bash "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --fail-fast -- config --quiet
  assert_output --regexp .*"\[NBS\]".*"Environment variables".*"(build matrix)".*"set for compose:".*"NBS_MATRIX_REPOSITORY_VERSIONS=\(latest\)".*"NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS=\(bionic focal jammy\)"

}

# ....Flag related tests...........................................................................
@test "${TESTED_FILE} › flags are passed across script and function as expected › expect pass" {

  setup_dotenv_build_matrix_dependencies

  run bash "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --fail-fast -- build --push
  assert_output --regexp .*"\[NBS\]".*"Environment variables".*"(build matrix)".*"set for compose:".*"NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS=\(bionic focal jammy\)"
  assert_output --regexp .*"\[NBS done\]".*"FINAL › Build matrix completed with command".*"\$".*"docker compose -f ${COMPOSE_FILE}".*"build --push"

  run bash "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --ubuntu-version-build-matrix-override jammy --fail-fast -- config --quiet
  assert_success
  assert_output --regexp .*"\[NBS\]".*"Environment variables".*"(build matrix)".*"set for compose:".*"NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS=\(jammy\)"
  assert_output --regexp .*"\[NBS done\]".*"FINAL › Build matrix completed with command".*"\$".*"docker compose -f ${COMPOSE_FILE}".*"config --quiet"
}

# ....Build matrix tests...........................................................................
@test "${TESTED_FILE} › dependencies image › execute ok › expect pass" {

  setup_dotenv_build_matrix_dependencies

  run bash "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --fail-fast -- build
  assert_success
  assert_output --regexp .*"Starting".*"${TESTED_FILE}".*"\[NBS\]".*"Build images specified in".*"'docker-compose.dependencies.yaml'".*"following".*"${DOTENV_BUILD_MATRIX_NAME}"
  assert_output --regexp "Status of tag crawled:".*"Pass".*"› latest-ubuntu-bionic".*"Pass".*"› latest-ubuntu-focal".*"Completed".*"${TESTED_FILE}".*
}

@test "${TESTED_FILE} › project-core image › execute ok › expect pass" {

  setup_dotenv_build_matrix_superproject

  run bash "${TESTED_FILE}" "${DOTENV_BUILD_MATRIX}" --fail-fast -- build
  assert_success
  assert_output --regexp .*"Starting".*"${TESTED_FILE}".*"\[NBS\]".*"Build images specified in".*"'docker-compose.project_core.yaml'".*"following".*"${DOTENV_BUILD_MATRIX_NAME}"
  assert_output --regexp "Status of tag crawled:".*"Pass".*"› latest-ubuntu-bionic Compile mode: Release".*"Pass".*"› latest-ubuntu-bionic Compile mode: RelWithDebInfo".*"Pass".*"› latest-ubuntu-bionic Compile mode: MinSizeRel".*"Pass".*"› latest-ubuntu-focal Compile mode: Release".*"Pass".*"› latest-ubuntu-focal Compile mode: RelWithDebInfo".*"Pass".*"› latest-ubuntu-focal Compile mode: MinSizeRel".*"Pass".*"› latest-ubuntu-jammy Compile mode: Release".*"Pass".*"› latest-ubuntu-jammy Compile mode: RelWithDebInfo".*"Pass".*"› latest-ubuntu-jammy Compile mode: MinSizeRel".*"Completed".*"${TESTED_FILE}".*
}

# ....Test --help flag related logic...............................................................
@test "${TESTED_FILE} › --help as first argument › execute ok › expect pass" {

  setup_dotenv_build_matrix_superproject

  run bash "${TESTED_FILE}" --help "$DOTENV_BUILD_MATRIX"
  assert_success
  assert_output --regexp .*"Starting".*"${TESTED_FILE}".*"\$".*"${TESTED_FILE} \[--help\] <.env.build_matrix.*> \[<optional flag>\] \[-- <any docker cmd\+arg>\]".*"Mandatory argument:".*"<.env.build_matrix.*>".*"Optional arguments:".*"-h, --help".*"--docker-debug-logs".*"--fail-fast"
  refute_output --regexp .*"Starting".*"${TESTED_FILE}".*"\[NBS\]".*"Build images specified in".*"'docker-compose.project_core.yaml'".*"following".*"${DOTENV_BUILD_MATRIX_NAME}"
}


@test "${TESTED_FILE} › first arg: dotenv, second arg: --help › execute ok › expect pass" {

  setup_dotenv_build_matrix_superproject

  run bash "${TESTED_FILE}" "$DOTENV_BUILD_MATRIX" --help
  assert_success
  assert_output --regexp .*"Starting".*"${TESTED_FILE}".*"\$".*"${TESTED_FILE} \[--help\] <.env.build_matrix.*> \[<optional flag>\] \[-- <any docker cmd\+arg>\]".*"Mandatory argument:".*"<.env.build_matrix.*>".*"Optional arguments:".*"-h, --help".*"--docker-debug-logs".*"--fail-fast"
  refute_output --regexp .*"Starting".*"${TESTED_FILE}".*"\[NBS\]".*"Build images specified in".*"'docker-compose.project_core.yaml'".*"following".*"${DOTENV_BUILD_MATRIX_NAME}"
}

@test "${TESTED_FILE} › first arg: dotenv, third arg: --help › execute ok › expect pass" {

  setup_dotenv_build_matrix_superproject

  run bash "${TESTED_FILE}" "$DOTENV_BUILD_MATRIX" --fail-fast --help
  assert_success
  assert_output --regexp .*"Starting".*"${TESTED_FILE}".*"\$".*"${TESTED_FILE} \[--help\] <.env.build_matrix.*> \[<optional flag>\] \[-- <any docker cmd\+arg>\]".*"Mandatory argument:".*"<.env.build_matrix.*>".*"Optional arguments:".*"-h, --help".*"--docker-debug-logs".*"--fail-fast"
  refute_output --regexp .*"Starting".*"${TESTED_FILE}".*"\[NBS\]".*"Build images specified in".*"'docker-compose.project_core.yaml'".*"following".*"${DOTENV_BUILD_MATRIX_NAME}"
}

# ....Test bad input parameter.....................................................................
@test "${TESTED_FILE} › case where the dotenv build matrix is missing with or without a --help flag › execute ok › expect pass" {

  setup_dotenv_build_matrix_superproject

  run bash "${TESTED_FILE}" --fail-fast --help

  assert_failure
  assert_output --regexp .*"\[".*"ERROR".*"\]".*"${TESTED_FILE}".*"Unexpected argument".*"--fail-fast".*"Unless you pass the".*"--help".*"flag, the first argument must be a".*".env.build_matrix".*"file."
}

# ToDo: implement >> test for IS_TEAMCITY_RUN==true casses
# (NICE TO HAVE) ToDo: implement >> test for python intsall casses with regard to distribution

