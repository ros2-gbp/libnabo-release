#!/bin/bash
#
# Utility script to create a multi-architecture docker builder
#
# usage:
#   $ bash ./install_scripts/nbs_create_multiarch_docker_builder.bash
#

function nbs::create_multiarch_docker_builder() {
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

  # ====Begin======================================================================================
  print_formated_script_header 'nbs_create_multiarch_docker_builder.bash' "${MSG_LINE_CHAR_UTIL}"

  # ...............................................................................................
  echo
  print_msg "Create a multi-architecture docker builder"
  echo

  docker buildx create \
    --name local-builder-multiarch-virtualization \
    --driver docker-container \
    --platform linux/amd64,linux/arm64 \
    --bootstrap \
    --use

  docker buildx ls

  print_formated_script_footer 'nbs_create_multiarch_docker_builder.bash' "${MSG_LINE_CHAR_UTIL}"
  # ====Teardown===================================================================================
  cd "${TMP_CWD}"
}

# ::::main:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
nbs::create_multiarch_docker_builder
