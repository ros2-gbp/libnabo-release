#!/bin/bash

# ....path resolution logic........................................................................
_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
LPM_ROOT_DIR="$(dirname "${_PATH_TO_SCRIPT}")"
cd "${LPM_ROOT_DIR}/../../"

# ====begin========================================================================================
set -o allexport
source ./build_system_templates/.env
set +o allexport

cd src/utility_scripts

DOTENV_BUILD_MATRIX=${LPM_ROOT_DIR}/../../build_system_templates/.env.build_matrix.project.template

#export BUILDKIT_PROGRESS=plain # ToDo: on dev task end >> mute this line ←

unset FLAGS
declare -a FLAGS
#FLAGS+=( --no-cache )
#FLAGS+=( --dry-run )

bash nbs_execute_compose_over_build_matrix.bash "${DOTENV_BUILD_MATRIX}" --fail-fast -- build "${FLAGS[@]}"
