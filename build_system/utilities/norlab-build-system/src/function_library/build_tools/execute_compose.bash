#!/bin/bash
#
# Build and run a single container based on a norlab-build-system docker-compose.yaml file
#
# Usage example:
#   $ cd <path/to/norlab-build-system/root>
#   $ source import_norlab_build_system_lib.bash
#   $ nbs::execute_compose -- run --rm ci
#
# Signature:
#   $ nbs::execute_compose [--help] <docker-compose.yaml> [<optional flag>] [-- <any docker cmd+arg>]
#
# Mandatory argument:
#   <docker-compose.yaml>                 Absolute path to the docker compose file with container specifications
#
# Optional arguments:
#   [--repository-version <version>]      The repository release tag (default: see REPOSITORY_VERSION)
#   [--cmake-build-type <flag-name>]           Change the cmake compilation mode.
#                                         Either 'None' 'Debug' 'Release' 'RelWithDebInfo' or 'MinSizeRel'
#   [--os-name <name>]                    The operating system name. Either 'ubuntu' or 'osx' (default: see OS_NAME)
#   [--os-version <version>]              Name named operating system version, see .env for supported version
#                                           (default: see OS_VERSION)
#   [-- <any docker cmd+arg>]             Any argument passed after '--' will be passed to docker compose
#                                           as docker command and arguments (default: 'up --build --force-recreate')
#                                         Note: passing script flag via docker --build-arg can be tricky,
#                                               pass them in the docker-compose.yaml if you experience problem.
#   [--docker-debug-logs]                 Set Docker builder log output for debug (i.e.BUILDKIT_PROGRESS=plain)
#   [--fail-fast]                         Exit script at first encountered error
#   [-h, --help]                          Get help
#
#
#
# Note:
#   Dont use "set -e" in this script as it will affect the build system policy, use the --fail-fast flag instead
#


function nbs::execute_compose() {
  # ....Default....................................................................................
  REPOSITORY_VERSION='latest'
  CMAKE_BUILD_TYPE='RelWithDebInfo'
  OS_NAME='ubuntu'
  OS_VERSION='focal'
  DOCKER_COMPOSE_CMD_ARGS='build --dry-run'  # alt: "build --no-cache --push" or "up --build --force-recreate"

  # ....Project root logic.........................................................................
  local TMP_CWD=$(pwd)

  function nbs::print_help_in_terminal() {
    echo -e "\n
  \$ nbs::execute_compose [--help] <docker-compose.yaml> [<optional flag>] [-- <any docker cmd+arg>]
    \033[1m
      Mandatory argument:\033[0m
        <docker-compose.yaml>           Absolute path to the docker compose file with container specifications
    \033[1m
      Optional arguments:\033[0m
        -h, --help                      Get help
        --repository-version <version>  The repository release tag (default to master branch latest)
        --cmake-build-type <flag-name>
                                        Change the cmake compilation mode.
                                        Either 'None' 'Debug' 'Release' 'RelWithDebInfo' or 'MinSizeRel'
        --os-name <name>                The operating system name. Either 'ubuntu' or 'osx' (default to 'ubuntu')
        --os-version <version>              Name named operating system version, see .env for supported version
                                        (default to 'jammy')
        --docker-debug-logs             Set Docker builder log output for debug (i.e.BUILDKIT_PROGRESS=plain)
        --fail-fast                     Exit script at first encountered error
    \033[1m
      [-- <any docker cmd+arg>]\033[0m         Any argument passed after '--' will be passed to docker compose as docker
                                        command and arguments (default to '${DOCKER_COMPOSE_CMD_ARGS}').
                                        Note: passing script flag via docker --build-arg can be tricky,
                                              pass them in the docker-compose.yaml if you experience problem.
  "
  }

  # ....TeamCity service message logic.............................................................
  if [[ ${TEAMCITY_VERSION} ]]; then
    export IS_TEAMCITY_RUN=true
    TC_VERSION="TEAMCITY_VERSION=${TEAMCITY_VERSION}"
  else
    export IS_TEAMCITY_RUN=false
  fi
  print_msg "IS_TEAMCITY_RUN=${IS_TEAMCITY_RUN} ${TC_VERSION}"

  # ====Begin======================================================================================
  SHOW_SPLASH_EC="${SHOW_SPLASH_EC:-true}"

  if [[ "${SHOW_SPLASH_EC}" == 'true' ]]; then
    norlab_splash "${NBS_SPLASH_NAME_BUILD_SYSTEM}" "https://github.com/${NBS_REPOSITORY_DOMAIN}/${NBS_REPOSITORY_NAME}"
  fi

  print_formated_script_header 'nbs::execute_compose' "${MSG_LINE_CHAR_BUILDER_LVL2}"

  # ....Script command line flags (help case)......................................................
  while [ $# -gt 0 ]; do

    case $1 in
    -h | --help)
      nbs::print_help_in_terminal
      exit
      ;;
    *) # Default case
      break
      ;;
    esac

  done


  # Handle unexpected argument: case missing the ".env.build_matrix"
  PARAM_TEST="$1"
  PARMA_TEST_FILE_EXTENSION=${PARAM_TEST##*.}
  if [[ ! .yaml == .${PARMA_TEST_FILE_EXTENSION} ]]; then
    echo -e "\n[\033[1;31mERROR\033[0m] nbs::execute_compose: Unexpected argument ${MSG_DIMMED_FORMAT}${PARAM_TEST}${MSG_END_FORMAT}. Unless you pass the ${MSG_DIMMED_FORMAT}--help${MSG_END_FORMAT} flag, the first argument must be a ${MSG_DIMMED_FORMAT}docker-compose.<name>.yaml${MSG_END_FORMAT} file." 1>&2
    exit 1
  fi

  _COMPOSE_FILE="${1:?'Missing the docker-compose.yaml file mandatory argument'}"
  shift # Remove argument value

  # ....Script command line flags..................................................................
  while [ $# -gt 0 ]; do

    case $1 in
    --repository-version)
      REPOSITORY_VERSION="${2}"
      shift # Remove argument (--repository-version)
      shift # Remove argument value
      ;;
    --cmake-build-type)
      CMAKE_BUILD_TYPE="${2}"
      shift # Remove argument (--cmake-build-type)
      shift # Remove argument value
      ;;
    --os-name)
      OS_NAME="${2}"
      shift # Remove argument (--os-name)
      shift # Remove argument value
      ;;
    --os-version)
      OS_VERSION="${2}"
      shift # Remove argument (--os-version)
      shift # Remove argument value
      ;;
    --docker-debug-logs)
  #    set -v
  #    set -x
      export BUILDKIT_PROGRESS=plain
      shift # Remove argument (--docker-debug-logs)
      ;;
    --fail-fast)
      set -e
      shift # Remove argument (--fail-fast)
      ;;
    -h | --help)
      nbs::print_help_in_terminal
      exit
      ;;
    --) # no more option
      shift
      DOCKER_COMPOSE_CMD_ARGS="$*"
      break
      ;;
    *) # Default case
      break
      ;;
    esac

  done

  if [[ ! -f ${_COMPOSE_FILE} ]]; then
    print_msg_error_and_exit "'nbs::execute_compose' docker-compose file ${_COMPOSE_FILE} is unreachable"
  fi

  # ...............................................................................................
  # Note: REPOSITORY_VERSION will be used to fetch the repo at release tag (ref task NMO-252)
  export REPOSITORY_VERSION="${REPOSITORY_VERSION}"
  export CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}"
  export DEPENDENCIES_BASE_IMAGE="${OS_NAME}"
  export DEPENDENCIES_BASE_IMAGE_TAG="${OS_VERSION}"

  export NBS_IMAGE_TAG="${REPOSITORY_VERSION}-${DEPENDENCIES_BASE_IMAGE}-${DEPENDENCIES_BASE_IMAGE_TAG}"

  print_msg "Environment variables set for compose:\n
  ${MSG_DIMMED_FORMAT}    REPOSITORY_VERSION=${REPOSITORY_VERSION} ${MSG_END_FORMAT}
  ${MSG_DIMMED_FORMAT}    CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${MSG_END_FORMAT}
  ${MSG_DIMMED_FORMAT}    DEPENDENCIES_BASE_IMAGE=${DEPENDENCIES_BASE_IMAGE} ${MSG_END_FORMAT}
  ${MSG_DIMMED_FORMAT}    DEPENDENCIES_BASE_IMAGE_TAG=${DEPENDENCIES_BASE_IMAGE_TAG} ${MSG_END_FORMAT}
  "

  print_msg "Executing docker compose command on ${MSG_DIMMED_FORMAT}${_COMPOSE_FILE}${MSG_END_FORMAT} with command ${MSG_DIMMED_FORMAT}${DOCKER_COMPOSE_CMD_ARGS}${MSG_END_FORMAT}"
  print_msg "Image tag ${MSG_DIMMED_FORMAT}${NBS_IMAGE_TAG}${MSG_END_FORMAT}"
  #${MSG_DIMMED_FORMAT}$(printenv | grep -i -e NBS_ -e DEPENDENCIES_BASE_IMAGE -e BUILDKIT)${MSG_END_FORMAT}

  ## docker compose [-f <theComposeFile> ...] [options] [COMMAND] [ARGS...]
  ## docker compose build [OPTIONS] [SERVICE...]
  ## docker compose run [OPTIONS] SERVICE [COMMAND] [ARGS...]

  show_and_execute_docker "compose -f ${_COMPOSE_FILE} ${DOCKER_COMPOSE_CMD_ARGS}"


  print_msg "Environment variables used by compose:\n
  ${MSG_DIMMED_FORMAT}    REPOSITORY_VERSION=${REPOSITORY_VERSION} ${MSG_END_FORMAT}
  ${MSG_DIMMED_FORMAT}    CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${MSG_END_FORMAT}
  ${MSG_DIMMED_FORMAT}    DEPENDENCIES_BASE_IMAGE=${DEPENDENCIES_BASE_IMAGE} ${MSG_END_FORMAT}
  ${MSG_DIMMED_FORMAT}    DEPENDENCIES_BASE_IMAGE_TAG=${DEPENDENCIES_BASE_IMAGE_TAG} ${MSG_END_FORMAT}"

  print_formated_script_footer 'nbs::execute_compose' "${MSG_LINE_CHAR_BUILDER_LVL2}"
  # ====Teardown===================================================================================
  cd "${TMP_CWD}"
}
