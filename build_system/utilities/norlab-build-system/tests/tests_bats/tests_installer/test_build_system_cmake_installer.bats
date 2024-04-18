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
TESTED_FILE="nbs_cmake_install_ubuntu.bash"
TESTED_FILE_PATH="./build_system_templates/installer"

# executed once before starting the first test (valide for all test in that file)
setup_file() {
  BATS_DOCKER_WORKDIR=$(pwd) && export BATS_DOCKER_WORKDIR
  export N2ST_PATH="$(git rev-parse --show-toplevel)/utilities/norlab-shell-script-tools"

  # Uncomment the following for debug, the ">&3" is for printing bats msg to stdin
#  pwd >&3 && tree -L 1 -a -hug >&3
#  pwd >&3 && tree -L 2 -a ./build_system/utilities >&3
#  printenv >&3
}

# executed before each test
setup() {
  echo "(Bats) Source project .env"
  set -o allexport
  source "${BATS_DOCKER_WORKDIR:?err}/build_system_templates/.env"
  set +o allexport

  cd "$TESTED_FILE_PATH" || exit 1
}

# ====Teardown=====================================================================================

# executed after each test
teardown() {
  echo "(Bats) Reset install directory"
  if [[ -d ${NBS_LIB_INSTALL_PATH}/dockerized-norlab-project-mock ]]; then
    rm -rf "${NBS_LIB_INSTALL_PATH}/dockerized-norlab-project-mock"
  fi

#  bats_print_run_env_variable_on_error
}

## executed once after finishing the last test (valide for all test in that file)
#teardown_file() {
#}

# ====Test casses==================================================================================
# ....Build system install script..................................................................

@test "Mock Project | run ${TESTED_FILE} (default) › expect pass" {
#  skip "tmp debug" # ToDo: on task end >> delete this line ←
  cd "${BATS_DOCKER_WORKDIR}"

  run bash "./${TESTED_FILE_PATH}/$TESTED_FILE" --test-run

  assert_success

  assert_output --regexp .*"\[".*"DN-mock".*"\]".*"Install dockerized-norlab-project-mock"

  assert_output --regexp .*"\[".*"DN-mock".*"\]".*"Execute".*"cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo -D PROJECT_BUILD_TESTS=OFF -D PROJECT_BUILD_DOXYGEN=OFF /opt/dockerized-norlab-project-mock"
  refute_output --regexp .*"\[".*"DN-mock".*"\]".*"Execute".*"cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo -D PROJECT_BUILD_TESTS=OFF -D PROJECT_BUILD_DOXYGEN=OFF -D CMAKE_INSTALL_PREFIX=/opt/opt/dockerized-norlab-project-mock"

  assert_output --regexp .*"\[".*"DN-mock done".*"\]".*"dockerized-norlab-project-mock installed successfully at".*
}

@test "Mock Project | run ${TESTED_FILE} (default) (read APPEND_TO_CMAKE_FLAG ok) › expect pass" {
#  skip "tmp debug" # ToDo: on task end >> delete this line ←
  cd "${BATS_DOCKER_WORKDIR}"

  export APPEND_TO_CMAKE_FLAG=( -D CMAKE_INSTALL_PREFIX=/opt/test_dir )
  run source "./${TESTED_FILE_PATH}/$TESTED_FILE" --test-run

  assert_success

  assert_output --regexp .*"\[".*"DN-mock".*"\]".*"Install dockerized-norlab-project-mock"

  assert_output --regexp .*"\[".*"DN-mock".*"\]".*"Execute".*"cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo -D PROJECT_BUILD_TESTS=OFF -D PROJECT_BUILD_DOXYGEN=OFF -D CMAKE_INSTALL_PREFIX=/opt/test_dir /opt/dockerized-norlab-project-mock"
  refute_output --regexp .*"\[".*"DN-mock".*"\]".*"Execute".*"cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo -D PROJECT_BUILD_TESTS=OFF -D PROJECT_BUILD_DOXYGEN=OFF /opt/dockerized-norlab-project-mock"

  assert_output --regexp .*"\[".*"DN-mock done".*"\]".*"dockerized-norlab-project-mock installed successfully at".*
}


@test "Mock Project | run ${TESTED_FILE} (argument check) › expect pass" {
#  skip "tmp debug" # ToDo: on task end >> delete this line ←
  cd "${BATS_DOCKER_WORKDIR}"

  run bash "./${TESTED_FILE_PATH}/$TESTED_FILE" --test-run \
             --install-path /opt/test_dir \
             --repository-version v0.0.1 \
             --compile-test \
             --generate-doc \
             --cmake-build-type Release

  assert_success
  assert_output --regexp .*"\[".*"DN-mock".*"\]".*"Install dockerized-norlab-project-mock"

  assert_output --partial "switching to 'tags/v0.0.1'."

  assert_output --regexp .*"\[".*"DN-mock".*"\]".*"Repository checkout at tag v0.0.1"

  assert_output --regexp .*"\[".*"DN-mock".*"\]".*"Execute".*"cmake -D CMAKE_BUILD_TYPE=Release -D PROJECT_BUILD_TESTS=ON -D PROJECT_BUILD_DOXYGEN=ON /opt/test_dir/dockerized-norlab-project-mock"
  refute_output --regexp .*"\[".*"DN-mock".*"\]".*"Execute".*"cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo -D PROJECT_BUILD_TESTS=OFF -D PROJECT_BUILD_DOXYGEN=OFF /opt/dockerized-norlab-project-mock"


  assert_output --regexp .*"\[".*"DN-mock done".*"\]".*"dockerized-norlab-project-mock installed successfully at".*

}
