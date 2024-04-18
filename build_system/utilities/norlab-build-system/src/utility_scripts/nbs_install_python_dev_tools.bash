#!/bin/bash
#
# Install python development tools
#
# usage:
#   $ bash nbs_install_python_dev_tools.bash
#
set -e

# ....Pre-condition................................................................................
if [[ "$(basename "$(pwd)")" != "utility_scripts" ]]; then
  echo -e "\n[\033[1;31mERROR\033[0m] 'nbs_install_python_dev_tools.bash' script must be executed from the 'norlab-build-system/src/utility_scripts/' directory!\n Curent working directory is '$(pwd)'" 1>&2
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi

# ....path resolution logic........................................................................
SCRIPT_PATH="$(realpath "$0")"
NBS_PATH="$( realpath "$(dirname "${SCRIPT_PATH}")/../.." )"

# ....Helper function..............................................................................
# import shell functions from utilities library
source "${NBS_PATH}/import_norlab_build_system_lib.bash"


# ====Begin========================================================================================
nbs::install_python_dev_tools
