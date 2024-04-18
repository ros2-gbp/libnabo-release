#!/bin/bash
# =================================================================================================
#
# Utility script to check the host architecture plus OS type and set IMAGE_ARCH_AND_OS environment variable as either
#       - IMAGE_ARCH_AND_OS=arm64\darwin
#       - IMAGE_ARCH_AND_OS=x86\linux
#       - IMAGE_ARCH_AND_OS=arm64\linux
#       - IMAGE_ARCH_AND_OS=arm64\l4t
# depending on which architecture and OS type the script is running:
#     - ARCH: aarch64, arm64, x86_64
#     - OS: Linux, Darwin, Window
#
# Usage:
#   $ cd <path/to/project>/norlab-shell-script-tools/src/utility_scripts
#   $ source ./which_architecture_and_os.bash
#
# Requirement: This script must be sourced from directory 'utility_scripts'
#
# Globals:
#   write IMAGE_ARCH_AND_OS
#
# Returns:
#   exit 1 in case of unsupported processor architecture
#
# =================================================================================================

# ....Pre-condition................................................................................
if [[ "$(basename "$(pwd)")" != "utility_scripts" ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] 'which_architecture_and_os.bash' script must be sourced from the 'utility_scripts/'!\n Curent working directory is '$(pwd)'" 1>&2
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
n2st::set_which_architecture_and_os

