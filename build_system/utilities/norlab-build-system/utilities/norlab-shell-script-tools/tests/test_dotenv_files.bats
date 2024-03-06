#!/usr/bin/env bats
#
# Usage in docker container
#   $ REPO_ROOT=$(pwd) && RUN_TESTS_IN_DIR='tests'
#   $ docker run -it --rm -v "$REPO_ROOT:/code" bats/bats:latest "$RUN_TESTS_IN_DIR"
#
#   Note: "/code" is the working directory in the bats official image
#
# bats-core ref:
#   - https://bats-core.readthedocs.io/en/stable/tutorial.html
#   - https://bats-core.readthedocs.io/en/stable/writing-tests.html
#   - https://opensource.com/article/19/2/testing-bash-bats
#       ↳ https://github.com/dmlond/how_to_bats/blob/master/test/build.bats
#
# Helper library: 
#   - https://github.com/bats-core/bats-assert
#   - https://github.com/bats-core/bats-support
#   - https://github.com/bats-core/bats-file
#

BATS_HELPER_PATH=/usr/lib/bats
if [[ -d ${BATS_HELPER_PATH} ]]; then
  load "${BATS_HELPER_PATH}/bats-support/load"
  load "${BATS_HELPER_PATH}/bats-assert/load"
  load "${BATS_HELPER_PATH}/bats-file/load"
  load "${SRC_CODE_PATH}/${N2ST_BATS_TESTING_TOOLS_RELATIVE_PATH}/bats_helper_functions"
  #load "${BATS_HELPER_PATH}/bats-detik/load" # << Kubernetes support
else
  echo -e "\n[\033[1;31mERROR\033[0m] $0 path to bats-core helper library unreachable at \"${BATS_HELPER_PATH}\"!" 1>&2
  echo '(press any key to exit)'
  read -r -n 1
  exit 1
fi

# ====Setup========================================================================================

setup_file() {
  BATS_DOCKER_WORKDIR=$(pwd) && export BATS_DOCKER_WORKDIR
#  pwd >&3 && tree -L 1 -a -hug >&3
#  printenv >&3
}

#setup() {
#}

# ====Teardown=====================================================================================

teardown() {
  bats_print_run_env_variable_on_error
#  printenv
}

#teardown_file() {
#    echo "executed once after finishing the last test"
#}

# ====Test casses==================================================================================
# Livetemplate shortcut: @test

function _source_dotenv() {
  local DOTENV_FILE="$1"
  set -o allexport
  # shellcheck disable=SC1090
  source "${BATS_DOCKER_WORKDIR:?err}/${DOTENV_FILE}"
  set +o allexport
}

function source_dotenv_msg_style() {
  _source_dotenv "src/function_library/.env.msg_style"
}

function source_dotenv_n2st() {
  _source_dotenv ".env.n2st"
}

function source_dotenv_project() {
  _source_dotenv ".env.project"
}

# ----.env.msg_style-------------------------------------------------------------------------------
@test ".env.msg_style › Env variable MSG_PROMPT_NAME › variable substitution › expect fail" {
  assert_empty "$PROJECT_PROMPT_NAME"
  assert_empty "$PROJECT_GIT_NAME"

  run source_dotenv_msg_style
  assert_failure
  assert_output --regexp "ERROR: set PROJECT_PROMPT_NAME or source .env.project first!"
#  bats_print_run_env_variable

}

@test ".env.msg_style › Env variable MSG_PROMPT_NAME › variable substitution to default" {
  source_dotenv_project
  assert_empty "$PROJECT_PROMPT_NAME"
  assert_not_empty "$PROJECT_GIT_NAME"
  run source_dotenv_msg_style
  assert_success
  source_dotenv_msg_style
  assert_equal "$MSG_PROMPT_NAME" "$PROJECT_GIT_NAME"

#  printenv  >&3
#  bats_print_run_env_variable
}

@test ".env.msg_style › Env variable MSG_PROMPT_NAME › variable substitution to custom" {
  source_dotenv_n2st
  assert_not_empty "$PROJECT_PROMPT_NAME"
  assert_not_empty "$PROJECT_GIT_NAME"
  run source_dotenv_msg_style
  assert_success
  source_dotenv_msg_style
  assert_equal "$MSG_PROMPT_NAME" "$PROJECT_PROMPT_NAME"

}

@test ".env.msg_style › Env variables MSG exists and are not empty " {
  printenv | grep -e 'MSG_'

  source_dotenv_n2st
  source_dotenv_msg_style

  # ....Tests......................................................................................
  assert_not_empty "${MSG_EMPH_FORMAT}"
  assert_not_empty "${MSG_DIMMED_FORMAT}"
  assert_not_empty "${MSG_BASE_FORMAT}"
  assert_not_empty "${MSG_ERROR_FORMAT}"
  assert_not_empty "${MSG_DONE_FORMAT}"
  assert_not_empty "${MSG_WARNING_FORMAT}"
  assert_not_empty "${MSG_END_FORMAT}"
  assert_not_empty "${MSG_AWAITING_INPUT}"
  assert_not_empty "${MSG_BASE}"
  assert_not_empty "${MSG_DONE}"
  assert_not_empty "${MSG_WARNING}"
  assert_not_empty "${MSG_ERROR}"

}

@test ".env.msg_style › Env variables MSG FORMAT have the proper escape character" {
  printenv | grep -e 'MSG_'

  source_dotenv_n2st
  source_dotenv_msg_style

  # ....Tests......................................................................................
  # Bash regex ref https://www.gnu.org/software/bash/manual/bash.html#Conditional-Constructs
  # The Patern "\033\[".* escape both | and [ which must be quoted and then math any number of char
  # shellcheck disable=SC2125
  local ESCAPE_CHAR="\033\[".*
  assert_regex "${MSG_EMPH_FORMAT}" "${ESCAPE_CHAR}"
  assert_regex "${MSG_DIMMED_FORMAT}" "${ESCAPE_CHAR}"
  assert_regex "${MSG_BASE_FORMAT}" "${ESCAPE_CHAR}"
  assert_regex "${MSG_ERROR_FORMAT}" "${ESCAPE_CHAR}"
  assert_regex "${MSG_DONE_FORMAT}" "${ESCAPE_CHAR}"
  assert_regex "${MSG_WARNING_FORMAT}" "${ESCAPE_CHAR}"
  assert_regex "${MSG_END_FORMAT}" "${ESCAPE_CHAR}"

}

@test ".env.msg_style › Env variables MSG FORMAT_TEAMCITY exists and are not empty" {
  printenv | grep -e 'MSG_'

  source_dotenv_n2st
  source_dotenv_msg_style

  # ....Tests......................................................................................
  assert_not_empty "${MSG_DIMMED_FORMAT_TEAMCITY}"
  assert_not_empty "${MSG_BASE_FORMAT_TEAMCITY}"
  assert_not_empty "${MSG_ERROR_FORMAT_TEAMCITY}"
  assert_not_empty "${MSG_WARNING_FORMAT_TEAMCITY}"
  assert_not_empty "${MSG_STEP_FORMAT_TEAMCITY}"
  assert_not_empty "${MSG_END_FORMAT_TEAMCITY}"
  assert_not_empty "${MSG_BASE_TEAMCITY}"

}


@test ".env.msg_style › Env variables MSG FORMAT_TEAMCITY match the teamcity escape character" {
  printenv | grep -e 'MSG_'

  source_dotenv_n2st
  source_dotenv_msg_style

  # ....Tests......................................................................................
  # Bash regex ref https://www.gnu.org/software/bash/manual/bash.html#Conditional-Constructs
  # The Patern "\|\[".* escape both | and [ which must be quoted and then math any number of char
  # shellcheck disable=SC2125
  local TEAMCITY_ESCAPE_CHAR="\|\[".*
  assert_regex "${MSG_DIMMED_FORMAT_TEAMCITY}" "${TEAMCITY_ESCAPE_CHAR}"
  assert_regex "${MSG_BASE_FORMAT_TEAMCITY}" "${TEAMCITY_ESCAPE_CHAR}"
  assert_regex "${MSG_ERROR_FORMAT_TEAMCITY}" "${TEAMCITY_ESCAPE_CHAR}"
  assert_regex "${MSG_WARNING_FORMAT_TEAMCITY}" "${TEAMCITY_ESCAPE_CHAR}"
  assert_regex "${MSG_STEP_FORMAT_TEAMCITY}" "${TEAMCITY_ESCAPE_CHAR}"
  assert_regex "${MSG_END_FORMAT_TEAMCITY}" "${TEAMCITY_ESCAPE_CHAR}"
  assert_regex "${MSG_BASE_TEAMCITY}" "${TEAMCITY_ESCAPE_CHAR}"
}

# ----.env.n2st------------------------------------------------------------------------------------
@test ".env.n2st › Env variables set ok" {
  # ....Pre-condition..............................................................................
  assert_empty ${PROJECT_PROMPT_NAME}
  assert_empty ${PROJECT_GIT_REMOTE_URL}
  assert_empty ${PROJECT_GIT_NAME}
  assert_empty ${PROJECT_SRC_NAME}
  assert_empty ${PROJECT_PATH}

  assert_empty ${N2ST_PROMPT_NAME}
  assert_empty ${N2ST_GIT_REMOTE_URL}
  assert_empty ${N2ST_GIT_NAME}
  assert_empty ${N2ST_SRC_NAME}
  assert_empty ${N2ST_PATH}

  # ....Source .env.project........................................................................
  source_dotenv_n2st
#  printenv | grep -e 'CONTAINER_PROJECT_' -e 'PROJECT_' >&3

  # ....Tests......................................................................................
  assert_equal "${PROJECT_PROMPT_NAME}" "N2ST"
  assert_regex "${PROJECT_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${PROJECT_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${PROJECT_SRC_NAME}" "norlab-shell-script-tools"
  assert_equal "${PROJECT_PATH}" "/code/norlab-shell-script-tools"

  assert_equal "${N2ST_PROMPT_NAME}" "N2ST"
  assert_regex "${N2ST_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${N2ST_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_SRC_NAME}" "norlab-shell-script-tools"
  assert_equal "${N2ST_PATH}" "/code/norlab-shell-script-tools"
}

# ----.env.project---------------------------------------------------------------------------------
@test ".env.project › Sourced in N2ST repo › Env variables set ok" {
  source_dotenv_project
#  printenv | grep -e 'CONTAINER_PROJECT_' -e 'PROJECT_' >&3

  assert_regex "${PROJECT_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/norlab-shell-script-tools"'(".git")?'
  assert_equal "${PROJECT_GIT_NAME}" "norlab-shell-script-tools"
  assert_equal "${PROJECT_PATH}" "/code/norlab-shell-script-tools"
  assert_equal "${PROJECT_SRC_NAME}" "norlab-shell-script-tools"
}

@test ".env.project › Source in a superproject › Env variables set ok" {
  TEST_N2ST_PATH="/code/norlab-shell-script-tools"
  SUPERPROJECT_NAME="dockerized-norlab-project-mock"
  SUPERPROJECT_PATH="/code/${SUPERPROJECT_NAME}"

  # ....Pre-condition..............................................................................
  assert_empty ${PROJECT_PROMPT_NAME}
  assert_empty ${PROJECT_GIT_REMOTE_URL}
  assert_empty ${PROJECT_GIT_NAME}
  assert_empty ${PROJECT_SRC_NAME}
  assert_empty ${PROJECT_PATH}

  assert_empty ${N2ST_PROMPT_NAME}
  assert_empty ${N2ST_GIT_REMOTE_URL}
  assert_empty ${N2ST_GIT_NAME}
  assert_empty ${N2ST_SRC_NAME}
  assert_empty ${N2ST_PATH}

  # ....Setup superproject.........................................................................
  assert_equal "$(pwd)" "$TEST_N2ST_PATH"
  cd ..
  assert_equal "$(pwd)" "/code"

  git clone "https://github.com/norlab-ulaval/${SUPERPROJECT_NAME}.git"
  assert_dir_exist "${SUPERPROJECT_NAME}"

#  # Visualise the testing directories
#  (echo && pwd && tree -L 2 -a) >&3


  # ....Source .env.project........................................................................
  cd "${SUPERPROJECT_NAME}"
  assert_equal "$(pwd)" "${SUPERPROJECT_PATH}"

  set -o allexport && source "$TEST_N2ST_PATH/.env.project" && set +o allexport

#  # Visualise generated environment variables
#  (echo && printenv | grep -e PROJECT_ && echo) >&3

  # ....Tests......................................................................................
  assert_regex "${PROJECT_GIT_REMOTE_URL}" "https://github.com/norlab-ulaval/${SUPERPROJECT_NAME}"'(".git")?'
  assert_equal "${PROJECT_GIT_NAME}" "${SUPERPROJECT_NAME}"
  assert_equal "${PROJECT_PATH}" "${SUPERPROJECT_PATH}"
  assert_equal "${PROJECT_SRC_NAME}" "${SUPERPROJECT_NAME}"
  assert_equal "${PROJECT_SRC_NAME}" "dockerized-norlab-project-mock"

  # ....Teardown this test case ...................................................................
  # Delete cloned repository mock
  rm -rf "$SUPERPROJECT_PATH"
}
