#!/bin/bash
#
# Execute build matrix over docker compose file specified in '.env.build_matrix.<mySuperProject>'
#
# Usage:
#   $ cd <path/to>/norlab-build-system/src/utility_scripts/
#   $ bash nbs_execute_compose_over_build_matrix.bash [--help] <.env.build_matrix.*> [<optional flag>] [-- <any docker cmd+arg>]
#
#  e.g.:
#   $ bash nbs_execute_compose_over_build_matrix.bash ".env.build_matrix" -- build --dry-run
#
# Mandatory argument:
#   <.env.build_matrix.*>       Absolute path to the dotenv file containing the build matrix
#
# Optional arguments:
#   [--repository-version-build-matrix-override <version>]
#                               The repository release tag. Override must be a single value
#                               (default to array sequence specified in .env.build_matrix)
#   [--cmake-build-type-build-matrix-override <flag-name>]
#                               Change the compilation mode.
#                               Either 'None' 'Debug' 'Release' 'RelWithDebInfo' or 'MinSizeRel'
#                               (default to array sequence specified in .env.build_matrix)
#   [--os-name-build-matrix-override <name>]
#                               The operating system name. Override must be a single value
#                               (default to array sequence specified in .env.build_matrix)
#   [--ubuntu-version-build-matrix-override <version>]
#   [--osx-version-build-matrix-override <version>]
#                               Named operating system version. Override must be a single value
#                               (default to array sequence specified in .env.build_matrix)
#   [-- <any docker cmd+arg>]
#                               Any argument passed after '--' will be passed to docker compose
#                                as docker command and arguments (default: 'build --dry-run')
#                               Note: passing script flag via docker --build-arg can be tricky,
#                                     pass them in the docker-compose.yaml if you experience problem.
#   [--docker-debug-logs]       Set Docker builder log output for debug (i.e.BUILDKIT_PROGRESS=plain)
#   [--fail-fast]               Exit script at first encountered error
#   [-h, --help]                Get help
#
# Note:
#   Dont use "set -e" in this script as it will affect the build system policy, use the --fail-fast flag instead
#

## Debug flags
#set -v
#set -x

# ....Pre-condition................................................................................
if [[ "$(basename "$(pwd)")" != "utility_scripts" ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] 'nbs_execute_compose_over_build_matrix.bash' script must be executed from the 'norlab-build-system/src/utility_scripts/' directory!\n Curent working directory is '$(pwd)'" 1>&2
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi

# ....path resolution logic........................................................................
SCRIPT_PATH="$(realpath "$0")"
NBS_PATH="$(dirname "${SCRIPT_PATH}")/../.."


# ....Helper function..............................................................................
# import shell functions from utilities library
source "${NBS_PATH}/import_norlab_build_system_lib.bash"

# ....Default......................................................................................
DOCKER_COMPOSE_CMD_ARGS='build --dry-run'
BUILD_STATUS_PASS=0

# ....Project root logic...........................................................................
TMP_CWD=$(pwd)

function print_help_in_terminal() {
  echo -e "\n
\$ $0 [--help] <.env.build_matrix.*> [<optional flag>] [-- <any docker cmd+arg>]
  \033[1m
    Mandatory argument:\033[0m
      <.env.build_matrix.*>
                          Absolute path to the dotenv file containing the build matrix
  \033[1m
    Optional arguments:\033[0m
      -h, --help          Get help
      --repository-version-build-matrix-override <version>
                          The repository release tag. Override must be a single value
                          (default to array sequence specified in .env.build_matrix)
      --cmake-build-type-build-matrix-override <flag-name>
                          Change the cmake compilation mode.
                          Either 'None' 'Debug' 'Release' 'RelWithDebInfo' or 'MinSizeRel'
                          (default to array sequence specified in .env.build_matrix)
      --os-name-build-matrix-override <name>
                          The operating system name. Override must be a single value
                          (default to array sequence specified in .env.build_matrix)
      --ubuntu-version-build-matrix-override <version>
      --osx-version-build-matrix-override <version>
                          Named operating system version. Override must be a single value
                          (default to array sequence specified in .env.build_matrix)
      --docker-debug-logs
                          Set Docker builder log output for debug (i.e.BUILDKIT_PROGRESS=plain)
      --fail-fast         Exit script at first encountered error

  \033[1m
    [-- <any docker cmd+arg>]\033[0m                 Any argument passed after '--' will be passed to docker compose as docker
                                              command and arguments (default to '${DOCKER_COMPOSE_CMD_ARGS}')
"
}

# ====Begin========================================================================================
norlab_splash "${NBS_SPLASH_NAME_BUILD_SYSTEM}" "https://github.com/${NBS_REPOSITORY_DOMAIN}/${NBS_REPOSITORY_NAME}"

print_formated_script_header "$0" "${MSG_LINE_CHAR_BUILDER_LVL1}"


# ....Script command line flag (help case).........................................................
while [ $# -gt 0 ]; do

  case $1 in
  -h | --help)
    print_help_in_terminal
    exit
    ;;
  *) # Default case
    break
    ;;
  esac

done

# ....Load environment variables from file.........................................................
DOTENV_BUILD_MATRIX_PATH="$1"

# Handle unexpected argument: case missing the ".env.build_matrix"
#set -x
PARAM_TEST=$( basename "$DOTENV_BUILD_MATRIX_PATH" ) || PARAM_TEST="${DOTENV_BUILD_MATRIX_PATH}"
if [[ ! .env.build_matrix. == ${PARAM_TEST:0:18} ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] '$0': Unexpected argument ${MSG_DIMMED_FORMAT}${PARAM_TEST}${MSG_END_FORMAT}. Unless you pass the ${MSG_DIMMED_FORMAT}--help${MSG_END_FORMAT} flag, the first argument must be a ${MSG_DIMMED_FORMAT}.env.build_matrix${MSG_END_FORMAT} file." 1>&2
  exit 1
fi


if [[ ! -f "${DOTENV_BUILD_MATRIX_PATH}" ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] '$0': dotenv file ${MSG_DIMMED_FORMAT}${DOTENV_BUILD_MATRIX}${MSG_END_FORMAT} is unreachable" 1>&2
  exit 1
else
  DOTENV_BUILD_MATRIX=$( basename "$DOTENV_BUILD_MATRIX_PATH" )
  BUILD_SYSTEM_CONFIG_DIR=$( dirname "$DOTENV_BUILD_MATRIX_PATH" )
  cd "$BUILD_SYSTEM_CONFIG_DIR"
  shift

  set -o allexport
  source "$DOTENV_BUILD_MATRIX"
  set +o allexport
fi


# ....Script command line flags....................................................................
while [ $# -gt 0 ]; do

  case $1 in
  --repository-version-build-matrix-override)
    unset NBS_MATRIX_REPOSITORY_VERSIONS
    NBS_MATRIX_REPOSITORY_VERSIONS=("$2")
    shift # Remove argument (--repository-version-build-matrix-override)
    shift # Remove argument value
    ;;
  --cmake-build-type-build-matrix-override)
    unset NBS_MATRIX_CMAKE_BUILD_TYPE
    NBS_MATRIX_CMAKE_BUILD_TYPE=("$2")
    shift # Remove argument (--cmake-build-type-build-matrix-override)
    shift # Remove argument value
    ;;
  --os-name-build-matrix-override)
    unset NBS_MATRIX_SUPPORTED_OS
    NBS_MATRIX_SUPPORTED_OS=("$2")
    shift # Remove argument (--os-name-build-matrix-override)
    shift # Remove argument value
    ;;
  --ubuntu-version-build-matrix-override)
    unset NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS
    NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS=("$2")
    shift # Remove argument (--ubuntu-version-build-matrix-override)
    shift # Remove argument value
    ;;
  --osx-version-build-matrix-override)
    unset NBS_MATRIX_OSX_SUPPORTED_VERSIONS
    NBS_MATRIX_OSX_SUPPORTED_VERSIONS=("$2")
    shift # Remove argument (--osx-version-build-matrix-override)
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
    print_help_in_terminal
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


# .................................................................................................
print_msg "Build images specified in ${MSG_DIMMED_FORMAT}'${NBS_EXECUTE_BUILD_MATRIX_OVER_COMPOSE_FILE:?'Environment variable is not set'}'${MSG_END_FORMAT} following ${MSG_DIMMED_FORMAT}${DOTENV_BUILD_MATRIX}${MSG_END_FORMAT}"

# Freeze build matrix env variable to prevent accidental override
# Note: declare -r ==> set as read-only, declare -a  ==> set as an array
declare -ra NBS_MATRIX_REPOSITORY_VERSIONS
declare -ra NBS_MATRIX_CMAKE_BUILD_TYPE
declare -ra NBS_MATRIX_SUPPORTED_OS
declare -ra NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS
declare -ra NBS_MATRIX_OSX_SUPPORTED_VERSIONS

print_msg "Environment variables ${MSG_EMPH_FORMAT}(build matrix)${MSG_END_FORMAT} set for compose:\n
${MSG_DIMMED_FORMAT}    NBS_MATRIX_REPOSITORY_VERSIONS=(${NBS_MATRIX_REPOSITORY_VERSIONS[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_CMAKE_BUILD_TYPE=(${NBS_MATRIX_CMAKE_BUILD_TYPE[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_SUPPORTED_OS=(${NBS_MATRIX_SUPPORTED_OS[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS=(${NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_OSX_SUPPORTED_VERSIONS=(${NBS_MATRIX_OSX_SUPPORTED_VERSIONS[*]}) ${MSG_END_FORMAT}
"

# Note: EACH_REPO_VERSION is used for container labeling and to fetch the repo at release tag
for EACH_REPO_VERSION in "${NBS_MATRIX_REPOSITORY_VERSIONS[@]}"; do
  if [[ ${TEAMCITY_VERSION} ]]; then
    echo -e "##teamcity[blockOpened name='${MSG_BASE_TEAMCITY} ${EACH_REPO_VERSION}']"
  fi

  for EACH_OS_NAME in "${NBS_MATRIX_SUPPORTED_OS[@]}"; do
    unset CRAWL_OS_VERSIONS

    if [[ ${EACH_OS_NAME} == 'ubuntu' ]]; then
      CRAWL_OS_VERSIONS=("${NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS[@]}")
    elif [[ ${EACH_OS_NAME} == 'osx' ]]; then
      CRAWL_OS_VERSIONS=("${NBS_MATRIX_OSX_SUPPORTED_VERSIONS[@]}")
    else
      print_msg_error_and_exit "${EACH_OS_NAME} not supported!"
    fi

    if [[ -z ${CRAWL_OS_VERSIONS} ]]; then
        print_msg_error_and_exit "Can't crawl ${EACH_OS_NAME} supported version array because it's empty!"
    fi

    if [[ ${TEAMCITY_VERSION} ]]; then
      echo -e "##teamcity[blockOpened name='${MSG_BASE_TEAMCITY} ${EACH_OS_NAME}']"
    fi

    for EACH_OS_VERSION in "${CRAWL_OS_VERSIONS[@]}"; do

      if [[ ${TEAMCITY_VERSION} ]]; then
        echo -e "##teamcity[blockOpened name='${MSG_BASE_TEAMCITY} ${EACH_OS_VERSION}']"
      fi

      for EACH_CMAKE_BUILD_TYPE in "${NBS_MATRIX_CMAKE_BUILD_TYPE[@]}"; do

        # shellcheck disable=SC2034
        SHOW_SPLASH_EC='false'

        if [[ ${TEAMCITY_VERSION} ]]; then
          echo -e "##teamcity[blockOpened name='${MSG_BASE_TEAMCITY} execute nbs::execute_compose' description='${MSG_DIMMED_FORMAT_TEAMCITY} --repository-version ${EACH_REPO_VERSION} --cmake-build-type ${EACH_CMAKE_BUILD_TYPE} --os-name ${EACH_OS_NAME} --os-version ${EACH_OS_VERSION} -- ${DOCKER_COMPOSE_CMD_ARGS}${MSG_END_FORMAT_TEAMCITY}|n']"
          echo " "
        fi

        nbs::execute_compose ${NBS_EXECUTE_BUILD_MATRIX_OVER_COMPOSE_FILE} \
                              --repository-version "${EACH_REPO_VERSION}" \
                              --cmake-build-type "${EACH_CMAKE_BUILD_TYPE}" \
                              --os-name "${EACH_OS_NAME}" \
                              --os-version "${EACH_OS_VERSION}" \
                              -- "${DOCKER_COMPOSE_CMD_ARGS}"

        # ....Collect image tags exported by nbs::execute_compose............................
        # Global: Read 'DOCKER_EXIT_CODE' env variable exported by function show_and_execute_docker
        if [[ ${DOCKER_EXIT_CODE} == 0 ]]; then
          MSG_STATUS="${MSG_DONE_FORMAT}Pass ${MSG_DIMMED_FORMAT}›"
          MSG_STATUS_TC_TAG="Pass ›"
        else
          MSG_STATUS="${MSG_ERROR_FORMAT}Fail ${MSG_DIMMED_FORMAT}›"
          MSG_STATUS_TC_TAG="Fail ›"
          BUILD_STATUS_PASS=$DOCKER_EXIT_CODE

          if [[ ${TEAMCITY_VERSION} ]]; then
            # Fail the build › Will appear on the TeamCity Build Results page
            echo -e "##teamcity[buildProblem description='BUILD FAIL with docker exit code: ${BUILD_STATUS_PASS}']"
          fi
        fi

        # Collect image tags exported by nbs::execute_compose
        # Global: Read 'NBS_IMAGE_TAG' env variable exported by nbs::execute_compose
        if [[ ${EACH_CMAKE_BUILD_TYPE} == 'None' ]] || [[ -z ${EACH_CMAKE_BUILD_TYPE} ]]; then
          IMAGE_TAG_CRAWLED=("${IMAGE_TAG_CRAWLED[@]}" "${MSG_STATUS} ${NBS_IMAGE_TAG}")
          IMAGE_TAG_CRAWLED_TC=("${IMAGE_TAG_CRAWLED_TC[@]}" "${MSG_STATUS_TC_TAG} ${NBS_IMAGE_TAG}")
        else
          IMAGE_TAG_CRAWLED=("${IMAGE_TAG_CRAWLED[@]}" "${MSG_STATUS} ${NBS_IMAGE_TAG} Compile mode: ${EACH_CMAKE_BUILD_TYPE}")
          IMAGE_TAG_CRAWLED_TC=("${IMAGE_TAG_CRAWLED_TC[@]}" "${MSG_STATUS_TC_TAG} ${NBS_IMAGE_TAG} Compile mode: ${EACH_CMAKE_BUILD_TYPE}")
        fi
        # .........................................................................................

        if [[ ${TEAMCITY_VERSION} ]]; then
          echo -e "##teamcity[blockClosed name='${MSG_BASE_TEAMCITY} execute nbs::execute_compose']"
        fi

      done

      if [[ ${TEAMCITY_VERSION} ]]; then
        echo -e "##teamcity[blockClosed name='${MSG_BASE_TEAMCITY} ${EACH_OS_VERSION}']"
      fi

    done

    if [[ ${TEAMCITY_VERSION} ]]; then
      echo -e "##teamcity[blockClosed name='${MSG_BASE_TEAMCITY} ${EACH_OS_NAME}']"
    fi

  done
  if [[ ${TEAMCITY_VERSION} ]]; then
    echo -e "##teamcity[blockClosed name='${MSG_BASE_TEAMCITY} ${EACH_REPO_VERSION}']"
  fi
done

echo " "
print_msg "Environment variables ${MSG_EMPH_FORMAT}(build matrix)${MSG_END_FORMAT} used by compose:\n
${MSG_DIMMED_FORMAT}    NBS_MATRIX_REPOSITORY_VERSIONS=(${NBS_MATRIX_REPOSITORY_VERSIONS[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_CMAKE_BUILD_TYPE=(${NBS_MATRIX_CMAKE_BUILD_TYPE[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_SUPPORTED_OS=(${NBS_MATRIX_SUPPORTED_OS[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS=(${NBS_MATRIX_UBUNTU_SUPPORTED_VERSIONS[*]}) ${MSG_END_FORMAT}
${MSG_DIMMED_FORMAT}    NBS_MATRIX_OSX_SUPPORTED_VERSIONS=(${NBS_MATRIX_OSX_SUPPORTED_VERSIONS[*]}) ${MSG_END_FORMAT}
"

print_msg_done "FINAL › Build matrix completed with command

${MSG_DIMMED_FORMAT}    $ docker compose -f ${NBS_EXECUTE_BUILD_MATRIX_OVER_COMPOSE_FILE} ${DOCKER_COMPOSE_CMD_ARGS} ${MSG_END_FORMAT}

Status of tag crawled:
"
for tag in "${IMAGE_TAG_CRAWLED[@]}" ; do
    echo -e "   ${tag}${MSG_END_FORMAT}"
done

print_formated_script_footer "$0" "${MSG_LINE_CHAR_BUILDER_LVL1}"

# ====TeamCity service message=====================================================================
if [[ ${TEAMCITY_VERSION} ]]; then
  # Tag added to the TeamCity build via a service message
  for tc_build_tag in "${IMAGE_TAG_CRAWLED_TC[@]}" ; do
      echo -e "##teamcity[addBuildTag '${tc_build_tag}']"
  done
fi

# ====Teardown=====================================================================================
cd "${TMP_CWD}"
exit $BUILD_STATUS_PASS
