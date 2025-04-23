#!/bin/bash
#
# General purpose function library
#
# Requirement: This script must be sourced from directory 'function_library'
#
# Usage:
#   $ cd <path/to/project>/norlab-shell-script-tools/src/function_library
#   $ source ./general_utilities.bash
#

# ....Pre-condition................................................................................
if [[ "$(basename "$(pwd)")" != "function_library" ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] 'general_utilities.bash' script must be sourced from the 'function_library/'!\n Curent working directory is '$(pwd)'" 1>&2
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
# Seek and modify a string in a file (modify in place)
#
# Usage:
#   $ n2st::seek_and_modify_string_in_file "<string to seek>" "<change to string>" <path/to/file>
#
# Arguments:
#   "<string to seek>"
#   "<change to string>"
#   <path/to/file>
# Outputs:
#   none
# Returns:
#   none
# =================================================================================================
function n2st::seek_and_modify_string_in_file() {

  local TMP_SEEK="${1}"
  local TMP_CHANGE_FOR="${2}"
  local TMP_FILE_PATH="${3}"

  # Note: Character ';' is used as a delimiter
  sudo sed --in-place "s;${TMP_SEEK};${TMP_CHANGE_FOR};" "${TMP_FILE_PATH}"

}

# =================================================================================================
# Check the current python version and set PYTHON3_VERSION environment variable
#
# Usage:
#   $ n2st::set_which_python3_version
#
# Globals:
#   write 'PYTHON3_VERSION'
# =================================================================================================
# (NICE TO HAVE) ToDo: extend unit-test
function n2st::set_which_python3_version() {
    PYTHON3_VERSION=$(python3 -c 'import sys; version=sys.version_info; print(f"{version.major}.{version.minor}")')
    export PYTHON3_VERSION
}

# =================================================================================================
# Check the host architecture plus OS type and set IMAGE_ARCH_AND_OS environment variable as either
#       - IMAGE_ARCH_AND_OS=arm64\darwin
#       - IMAGE_ARCH_AND_OS=x86\linux
#       - IMAGE_ARCH_AND_OS=arm64\linux
#       - IMAGE_ARCH_AND_OS=arm64\l4t
# depending on which architecture and OS type the script is running:
#     - ARCH: aarch64, arm64, x86_64
#     - OS: Linux, Darwin, Window
#
# Usage:
#   $ n2st::set_which_architecture_and_os
#
# Globals:
#   write IMAGE_ARCH_AND_OS
#
# Returns:
#   exit 1 in case of unsupported processor architecture
# =================================================================================================
# (NICE TO HAVE) ToDo: extend unit-test
# (NICE TO HAVE) ToDo: assessment >> check the convention used by docker >> os[/arch[/variant]]
#       linux/arm64/v8
#       darwin/arm64/v8
#       l4t/arm64/v8
#     ref: https://docs.docker.com/compose/compose-file/05-services/#platform
function n2st::set_which_architecture_and_os() {
  if [[ $(uname -m) == "aarch64" ]]; then
    if [[ -n $(uname -r | grep tegra) ]]; then
      export IMAGE_ARCH_AND_OS='l4t/arm64'
    elif [[ $(uname) == "Linux" ]]; then
        export IMAGE_ARCH_AND_OS='linux/arm64'
    else
      echo -e "${MSG_ERROR} Unsupported OS for aarch64 processor" 1>&2
    fi
  elif [[ $(uname -m) == "arm64" ]] && [[ $(uname) == "Darwin" ]]; then
    export IMAGE_ARCH_AND_OS='darwin/arm64'
  elif [[ $(uname -m) == "x86_64" ]] && [[ $(uname) == "Linux" ]]; then
    export IMAGE_ARCH_AND_OS='linux/x86'
  else
    n2st::print_msg_error_and_exit "Unsupported processor architecture"
  fi
}

# ====legacy API support===========================================================================
function seek_and_modify_string_in_file() {
  n2st::seek_and_modify_string_in_file "$@"
}

function set_which_python3_version() {
  n2st::set_which_python3_version "$@"
}

function set_which_architecture_and_os() {
  n2st::set_which_architecture_and_os "$@"
}
