#!/bin/bash
# =================================================================================================
#
# Utility script to check the current python version and set PYTHON3_VERSION environment variable
#
# Requirement: This script must be sourced from directory 'utility_scripts'
#
# Usage:
#   $ cd <path/to/project>/norlab-shell-script-tools/src/utility_scripts
#   $ source ./which_python_version.bash
#
# Globals:
#   write 'PYTHON3_VERSION'
#
# =================================================================================================


# ....Pre-condition................................................................................
if [[ "$(basename "$(pwd)")" != "utility_scripts" ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] 'which_python_version.bash' script must be sourced from the 'utility_scripts/'!\n Curent working directory is '$(pwd)'" 1>&2
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi

# ....Load helper function.........................................................................
TMP_CWD=$(pwd)

# (Priority) ToDo: validate!! (ref task NMO-388 fix: explicitly sourcing .env.n2st cause conflicting problem when the repo is used as a lib)
if [[ -z $PROJECT_PROMPT_NAME ]] && [[ -z $PROJECT_GIT_NAME ]] ; then
  set -o allexport
  source ../../.env.n2st
  set +o allexport
fi

cd ../function_library || exit 1
source ./general_utilities.bash

cd "${TMP_CWD}"

# ====Begin========================================================================================
n2st::set_which_python3_version

