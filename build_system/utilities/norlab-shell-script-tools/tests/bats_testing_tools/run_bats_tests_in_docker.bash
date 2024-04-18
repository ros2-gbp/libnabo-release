#!/bin/bash
#
# Execute bats unit test in a docker container with bats-core support including several helper libraries
#
# Usage:
#   $ cd my_project_root
#   $ bash ./tests/run_bats_tests_in_docker.bash ['<test-directory>[/<this-bats-test-file.bats>]' ['<image-distro>']]
#
# Arguments:
#   - ['<test-directory>']     The directory from which to start test, default to 'tests'
#   - ['<test-directory>/<this-bats-test-file.bats>']  A specific bats file to run, default will
#                                                      run all bats file in the test directory
#   - ['<image-distro>']          ubuntu or alpine (default ubuntu)
#

RUN_TESTS_IN_DIR=${1:-'tests'}
BATS_DOCKERFILE_DISTRO=${2:-'ubuntu'}

# ....Option.......................................................................................
## Set Docker builder log output for debug. Options: plain, tty or auto (default)
#export BUILDKIT_PROGRESS=plain

# ====Begin========================================================================================

# ....Project root logic...........................................................................
PROJECT_CLONE_GIT_ROOT=$(git rev-parse --show-toplevel)
PROJECT_CLONE_GIT_NAME=$(basename "$PROJECT_CLONE_GIT_ROOT" .git)
PROJECT_GIT_REMOTE_URL=$(git remote get-url origin)
PROJECT_GIT_NAME=$(basename "${PROJECT_GIT_REMOTE_URL}" .git)
REPO_ROOT=$(pwd)
N2ST_BATS_TESTING_TOOLS_ABS_PATH="$( cd "$( dirname "${0}" )" &> /dev/null && pwd )"
N2ST_BATS_TESTING_TOOLS_RELATIVE_PATH=".${N2ST_BATS_TESTING_TOOLS_ABS_PATH/$REPO_ROOT/}"

if [[ $(basename "$REPO_ROOT") != ${PROJECT_CLONE_GIT_NAME} ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] $0 must be executed from the project root!\nCurrent wordir: $(pwd)" 1>&2
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi



# Do not load MSG_BASE nor MSG_BASE_TEAMCITY from there .env file so that tested logic does not leak in that file
_MSG_BASE="\033[1m[${PROJECT_GIT_NAME}]\033[0m"
_MSG_BASE_TEAMCITY="|[${PROJECT_GIT_NAME}|]"

# ....Execute docker steps.........................................................................
# Note:
#   - CONTAINER_PROJECT_ROOT_NAME is for copying the source code including the repository root (i.e.: the project name)
#   - BUILDKIT_CONTEXT_KEEP_GIT_DIR is for setting buildkit to keep the .git directory in the container
#     Source https://docs.docker.com/build/building/context/#keep-git-directory

if [[ ${TEAMCITY_VERSION} ]]; then
  echo -e "##teamcity[blockOpened name='${_MSG_BASE_TEAMCITY} Build custom bats-core docker image']"
else
  echo -e "\n\n${_MSG_BASE} Building custom bats-core ${BATS_DOCKERFILE_DISTRO} docker image\n"
fi

docker build \
  --build-arg "CONTAINER_PROJECT_ROOT_NAME=${PROJECT_GIT_NAME}" \
  --build-arg BUILDKIT_CONTEXT_KEEP_GIT_DIR=1 \
  --build-arg N2ST_BATS_TESTING_TOOLS_RELATIVE_PATH="$N2ST_BATS_TESTING_TOOLS_RELATIVE_PATH" \
  --build-arg "TEAMCITY_VERSION=${TEAMCITY_VERSION}" \
  --file "${N2ST_BATS_TESTING_TOOLS_ABS_PATH}/Dockerfile.bats-core-code-isolation.${BATS_DOCKERFILE_DISTRO}" \
  --tag n2st-bats-test-code-isolation/"${PROJECT_GIT_NAME}" \
  --platform "linux/$(uname -m)" \
  --load \
  .

if [[ ${TEAMCITY_VERSION} ]]; then
  echo -e "##teamcity[blockClosed name='${_MSG_BASE_TEAMCITY} Build custom bats-core docker image']"
fi


if [[ ${TEAMCITY_VERSION} ]]; then
  echo -e "##teamcity[blockOpened name='${_MSG_BASE_TEAMCITY} Run bats-core tests']"
else
  echo -e "\n\n${_MSG_BASE} Starting bats-core test run on ${BATS_DOCKERFILE_DISTRO}\n"
fi

if [[ ${TEAMCITY_VERSION} ]]; then
  # The '--interactive' flag is not compatible with TeamCity build agent
  docker run --tty --rm n2st-bats-test-code-isolation/"${PROJECT_GIT_NAME}" "$RUN_TESTS_IN_DIR"
else
  docker run --interactive --tty --rm n2st-bats-test-code-isolation/"${PROJECT_GIT_NAME}" "$RUN_TESTS_IN_DIR"
fi
DOCKER_EXIT_CODE=$?

if [[ ${TEAMCITY_VERSION} ]] && [[ $DOCKER_EXIT_CODE != 0 ]]; then
  # Fail the build › Will appear on the TeamCity Build Results page
  echo -e "##teamcity[buildProblem description='BUILD FAIL with docker exit code: ${DOCKER_EXIT_CODE}']"
fi

if [[ ${TEAMCITY_VERSION} ]]; then
  echo -e "##teamcity[blockClosed name='${_MSG_BASE_TEAMCITY} Run bats-core tests']"
fi

# ====Teardown=====================================================================================
exit $DOCKER_EXIT_CODE
