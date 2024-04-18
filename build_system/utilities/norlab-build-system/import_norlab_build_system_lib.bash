#!/bin/bash
# =================================================================================================
# Import norlab-build-system function library and dependencies
#
# Usage in a interactive terminal session:
#
#   $ cd <path/to/norlab-build-system/root>
#   $ source import_norlab_build_system_lib.bash
#
# =================================================================================================

MSG_ERROR_FORMAT="\033[1;31m"
MSG_END_FORMAT="\033[0m"

function nbs::source_lib(){
  local TMP_CWD
  TMP_CWD=$(pwd)

  # ....path resolution logic......................................................................
  # Note: can handle both sourcing cases, ie from within a script and from an interactive terminal
  _PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[0]:-'.'}")"
  _REPO_ROOT="$(dirname "${_PATH_TO_SCRIPT}")"

  # ....Load environment variables from file.......................................................
  cd "${_REPO_ROOT}" || exit 1
  set -o allexport
  source .env.nbs
  set +o allexport

  # (NICE TO HAVE) ToDo: append lib to PATH (ref task NMO-414)
  # cd "${NBS_PATH}/src/build_tools"
  # PATH=$PATH:${NBS_PATH}/src/build_tools

  # ====Begin======================================================================================
  # ....Source NBS dependencies....................................................................
  cd "${N2ST_PATH}"
  source "import_norlab_shell_script_tools_lib.bash"

  # ....Source NBS functions.......................................................................
  cd "${NBS_PATH}/src/function_library/build_tools" || exit 1
  for each_file in "$(pwd)"/*.bash ; do
      source "${each_file}"
  done

  cd "${NBS_PATH}/src/function_library/container_tools" || exit 1
  for each_file in "$(pwd)"/*.bash ; do
      source "${each_file}"
  done

  cd "${NBS_PATH}/src/function_library/dev_tools" || exit 1
  for each_file in "$(pwd)"/*.bash ; do
      source "${each_file}"
  done

  # Set reference that the NBS library was imported with this script
  export NBS_IMPORTED=true

  # ====Teardown===================================================================================
  cd "${TMP_CWD}"
}

# ::::Main:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  # This script is being run, ie: __name__="__main__"
  echo -e "${MSG_ERROR_FORMAT}[ERROR]${MSG_END_FORMAT} This script must be sourced i.e.: $ source $( basename "$0" )" 1>&2
  exit 1
else
  # This script is being sourced, ie: __name__="__source__"
  nbs::source_lib
fi
