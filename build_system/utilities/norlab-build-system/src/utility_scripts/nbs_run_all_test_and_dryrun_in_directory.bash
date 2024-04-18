#!/bin/bash
#
# Run all bash script in a directory with name prefixed by "test_" or "dryrun_"
#
# Usage in a script:
#
#   #!/bin/bash
#   _PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
#   SCRIPT_DIR_PATH="$(dirname "${_PATH_TO_SCRIPT}")"
#   NBS_UTIL_SCRIPT="${SCRIPT_DIR_PATH}/../../src/utility_scripts"
#   source "${NBS_UTIL_SCRIPT}/nbs_run_all_test_and_dryrun_in_directory.bash" "$SCRIPT_DIR_PATH"
#




SCRIPT_DIR_PATH="${1:?'[ERROR] Missing mandatory path to directory to run script'}"

MSG_DIMMED_FORMAT="\033[1;2m"
MSG_ERROR_FORMAT="\033[1;31m"
MSG_END_FORMAT="\033[0m"

function nbs::run_all_script_in_directory(){
  set +e            # Propagate exit code ‹ Dont exit on error
  set +o pipefail   # Propagate exit code ‹ Dont exit if errors within pipes

  local _TMP_CWD
  _TMP_CWD=$(pwd)
  cd "${SCRIPT_DIR_PATH}" || exit 1

  local OVERALL_EXIT_CODE=0
  declare -a FILE_NAME

  # ====Begin======================================================================================
  # ....Run bash script prefixed with "dryrun_"....................................................
  for each_file in "${SCRIPT_DIR_PATH}"/dryrun_*.bash ; do
    if [[ -f $each_file ]]; then
      bash "${each_file}"
      EXIT_CODE=$?
      FILE_NAME+=( "   exit code $EXIT_CODE ‹ $( basename "${each_file}" )")
      if [[ ${EXIT_CODE} != 0 ]]; then
          OVERALL_EXIT_CODE=${EXIT_CODE}
      fi
    fi
  done

  # ....Run bash script prefixed with "test_"......................................................
  for each_file in "${SCRIPT_DIR_PATH}"/test_*.bash ; do
    if [[ -f $each_file ]]; then
      bash "${each_file}"
      EXIT_CODE=$?
      FILE_NAME+=( "   exit code $EXIT_CODE ‹ $( basename "${each_file}" )")
      if [[ ${EXIT_CODE} != 0 ]]; then
          OVERALL_EXIT_CODE=${EXIT_CODE}
      fi
    fi
  done

  echo -e "Results from ${MSG_DIMMED_FORMAT}$0${MSG_END_FORMAT} in directory ${MSG_DIMMED_FORMAT}$( basename "${SCRIPT_DIR_PATH}" )/${MSG_END_FORMAT} \n"
  for each_file_run in "${FILE_NAME[@]}" ; do
      echo "$each_file_run"
  done

  # ====Teardown===================================================================================
  cd "${_TMP_CWD}"

  return $OVERALL_EXIT_CODE
}

# ::::Main:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  # This script is being run, ie: __name__="__main__"
  echo -e "${MSG_ERROR_FORMAT}[ERROR]${MSG_END_FORMAT} This script must be sourced i.e.: $ source $( basename "$0" )" 1>&2
  exit 1
else
  # This script is being sourced, ie: __name__="__source__"
  nbs::run_all_script_in_directory
  exit $?
fi
