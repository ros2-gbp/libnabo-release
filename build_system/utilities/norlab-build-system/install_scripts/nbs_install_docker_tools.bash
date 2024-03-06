#!/bin/bash
#
# Utility script to install docker related tools and execute basic configuration
#
# usage:
#   $ bash ./install_scripts/nbs_install_docker_tools.bash
#

function nbs::install_docker_tools() {
  set -e

  local TMP_CWD
  TMP_CWD=$(pwd)


  # ....Project root logic.........................................................................
  NBS_PATH=$(git rev-parse --show-toplevel)

  # ....Load environment variables from file.......................................................
  cd "${NBS_PATH}" || exit 1
  set -o allexport
  source .env.nbs
  set +o allexport

  # ....Helper function............................................................................
  # import shell functions from utilities library
  N2ST_PATH=${N2ST_PATH:-"${NBS_PATH}/utilities/norlab-shell-script-tools"}
  cd "${N2ST_PATH}"
  source "import_norlab_shell_script_tools_lib.bash"

#  # ====Begin=====================================================================================
  cd "${N2ST_PATH}"/src/utility_scripts/ && bash install_docker_tools.bash

  # ====Teardown===================================================================================
  cd "${TMP_CWD}"
}

# ::::main:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
nbs::install_docker_tools
