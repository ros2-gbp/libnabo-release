#!/bin/bash
#
# General purpose function library
#
# Requirement: This script must be sourced from directory 'function_library'
#
# Usage:
#   $ cd <path/to/project>/norlab-shell-script-tools/src/function_library
#   $ source ./docker_utilities.bash
#

# ....Pre-condition................................................................................
if [[ "$(basename "$(pwd)")" != "function_library" ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] 'docker_utilities.bash' script must be sourced from the 'function_library/'!\n Curent working directory is '$(pwd)'" 1>&2
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi

# ....Load environment variables from file.........................................................
set -o allexport
source .env.msg_style
set +o allexport

# ....Load helper function.........................................................................
source ./prompt_utilities.bash

# =================================================================================================
# Show docker command and execute it. Just enclose the command with argument in quote.
#
# Usage:
#   $ n2st::show_and_execute_docker "<docker command with argument>"
#
#   Example usage:
#   $ n2st::show_and_execute_docker "run --name IamBuildSystemTester -t -i --rm lpm.ubuntu20.buildsystem.test"
#
# Globals:
#   Read 'IS_TEAMCITY_RUN'
# Outputs:
#   Output to STDOUT or STDERR
# Returns:
#   Return docker command exit code
# =================================================================================================
function n2st::show_and_execute_docker() {
  local FULL_DOCKER_COMMAND=$1
  local MOCK_DOCKER=${2:-false}
  unset DOCKER_EXIT_CODE

  if [ -f /.dockerenv ] && [[ $MOCK_DOCKER = false ]]; then
    echo
    n2st::print_msg_warning "Skipping the execution of Docker command\n
      ${MSG_DIMMED_FORMAT}$ docker ${FULL_DOCKER_COMMAND}${MSG_END_FORMAT}\n\nsince the script is executed inside a docker container ... and starting Docker daemon inside a container is complicated to setup and overkill for our testing case."
    DOCKER_EXIT_CODE=0
  else
    n2st::print_msg "Execute command ${MSG_DIMMED_FORMAT}$ docker ${FULL_DOCKER_COMMAND}${MSG_END_FORMAT}"

    # shellcheck disable=SC2086
    docker ${FULL_DOCKER_COMMAND}
    DOCKER_EXIT_CODE=$?

    SUCCESS_MSG="Command ${MSG_DIMMED_FORMAT}$ docker ${FULL_DOCKER_COMMAND}${MSG_END_FORMAT} completed successfully and exited docker."
    FAILURE_MSG="Command ${MSG_DIMMED_FORMAT}$ docker ${FULL_DOCKER_COMMAND}${MSG_END_FORMAT} exited with error (DOCKER_EXIT_CODE=${DOCKER_EXIT_CODE})!"

    if [[ ${DOCKER_EXIT_CODE} == 0 ]]; then
      # ToDo: assessment >> consider adding the logic to check "if run in teamcity" inside this function instead of relying on the IS_TEAMCITY_RUN env variable
      if [[ ${IS_TEAMCITY_RUN} == true ]]; then
        # Report message to build log
        echo -e "##teamcity[message text='${MSG_BASE_TEAMCITY} ${SUCCESS_MSG}' status='NORMAL']"
      else
        n2st::print_msg_done "${SUCCESS_MSG}"
      fi
    else
      if [[ ${IS_TEAMCITY_RUN} == true ]]; then
        # Report message to build log
        echo -e "##teamcity[message text='${MSG_BASE_TEAMCITY} ${FAILURE_MSG}' errorDetails='$DOCKER_EXIT_CODE' status='ERROR']"
      else
        n2st::print_msg_error "${FAILURE_MSG}"
      fi
    fi

  fi

  export DOCKER_EXIT_CODE
}


# =================================================================================================
# Add user to the docker group so that we dont have to preface docker command with sudo everytime
# Ref: https://docs.docker.com/engine/install/linux-postinstall/
#
# Note: `newgrp docker` command to activate the new docker group now cause the script to logout
#
# Usage:
#   $ n2st::add_user_to_the_docker_group <theUserName>
#
# Arguments:
#    <theUserName> The user name to add
# Outputs:
#   Feedback on what was executed
# =================================================================================================
function n2st::add_user_to_the_docker_group() {
  local THE_USER=$1

  n2st::print_msg "Manage Docker as a non-root user"

  sudo groupadd --force docker
  sudo usermod --append -G docker "${THE_USER}"
}

# ====legacy API support===========================================================================
function show_and_execute_docker() {
  n2st::show_and_execute_docker "$@"
}

function add_user_to_the_docker_group() {
  n2st::add_user_to_the_docker_group "$@"
}
