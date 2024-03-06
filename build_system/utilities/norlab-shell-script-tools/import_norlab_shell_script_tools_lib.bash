#!/bin/bash
# =================================================================================================
# Import norlab-shell-script-tools function library and dependencies
#
# Usage in a interactive terminal session:
#
#   $ cd <path/to/norlab-shell-script-tools/>
#   $ PROJECT_PROMPT_NAME=MySuperProject
#   $ source import_norlab_shell_script_tools_lib.bash
#
# Usage from within a shell script:
#
#   #!/bin/bash
#   cd <my/superproject/root>/utilities/norlab-shell-script-tools
#   source import_norlab_shell_script_tools_lib.bash
#
# =================================================================================================

MSG_DIMMED_FORMAT="\033[1;2m"
MSG_ERROR_FORMAT="\033[1;31m"
MSG_END_FORMAT="\033[0m"

function n2st::source_lib(){
  local TMP_CWD
  TMP_CWD=$(pwd)

  # Note: can handle both sourcing cases
  #   i.e. from within a script or from an interactive terminal session
  _PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[0]:-'.'}")"
  _REPO_ROOT="$(dirname "${_PATH_TO_SCRIPT}")"

  # ....Load environment variables from file.......................................................
  cd "${_REPO_ROOT}" || exit 1
  set -o allexport
  source .env.n2st
  set +o allexport

  # ....Begin......................................................................................
  cd "${N2ST_PATH:?'[ERROR] env var not set!'}/src/function_library" || exit 1
  for each_file in "$(pwd)"/*.bash ; do
      source "${each_file}"
  done

  # (NICE TO HAVE) ToDo: append lib to PATH (ref task NMO-414)
#  cd "${N2ST_ROOT_DIR}/src/utility_scripts"
#  PATH=$PATH:${N2ST_ROOT_DIR}/src/utility_scripts

  # ....Teardown...................................................................................
  cd "${TMP_CWD}"
}

# ::::Main:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  # This script is being run, ie: __name__="__main__"
  echo -e "${MSG_ERROR_FORMAT}[ERROR]${MSG_END_FORMAT} This script must be sourced i.e.: $ source $( basename "$0" )" 1>&2
  exit 1
else
  # This script is being sourced, ie: __name__="__source__"
  n2st::source_lib
fi

