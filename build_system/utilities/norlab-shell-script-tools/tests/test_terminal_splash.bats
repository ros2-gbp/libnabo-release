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
  echo -e "\n[\033[1;31mERROR\033[0m] $0 path to bats-core helper library unreachable at \"${BATS_HELPER_PATH}\"!"
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

setup() {
  cd "src/function_library" || exit 1
  source ./terminal_splash.bash
}

# ====Teardown=====================================================================================

teardown() {
  bats_print_run_env_variable_on_error
}

#teardown_file() {
#    echo "executed once after finishing the last test"
#}

# ====Test casses==================================================================================

@test "sourcing terminal_splash.bash ok › expect pass" {
  cd "${BATS_DOCKER_WORKDIR}/src/function_library/"
  run bash -c "PROJECT_GIT_NAME=$PROJECT_GIT_NAME && source ./terminal_splash.bash"
  assert_success
}

# ----n2st::echo_centering_str---------------------------------------------------------------------
@test "n2st::echo_centering_str › expect fail" {
  run n2st::echo_centering_str
  assert_failure

  run n2st::echo_centering_str "str"
  assert_failure

  run n2st::echo_centering_str "str" "\033[1m"
  assert_failure
}

@test "n2st::echo_centering_str › expect pass" {
  local CENTERED_STR="Test me"
  local THE_STYLE="\033[1m"
  local THE_PAD_CHAR="."

  run n2st::echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR"
  assert_success
  assert_output --partial "$CENTERED_STR"
  assert_output --partial "$THE_PAD_CHAR"

  run n2st::echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR" "+++" "---"
  assert_success
  assert_output --partial "$CENTERED_STR"
  assert_output --partial "$THE_PAD_CHAR"
  assert_output --partial "+++"
  assert_output --partial "---"

#  n2st::echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR" >&3
}

@test "n2st::echo_centering_str term special case ok" {
  local CENTERED_STR="Test me"
  local THE_STYLE="\033[1m"
  local THE_PAD_CHAR="."

  TERM=dumb
  run n2st::echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR"
  assert_success
  assert_output --partial "$CENTERED_STR"
  assert_output --partial "$THE_PAD_CHAR"

  unset TERM
  run n2st::echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR"
  assert_success
  assert_output --partial "$CENTERED_STR"
  assert_output --partial "$THE_PAD_CHAR"
}

@test "n2st::echo_centering_str teamcity special case ok" {
  local CENTERED_STR="Test me"
  local THE_STYLE="\033[1m"
  local THE_PAD_CHAR="."

  IS_TEAMCITY_RUN=true

  run n2st::echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR"
  assert_success
  assert_output --partial "...[0m"
}

# ----n2st::snow_splash----------------------------------------------------------------------------
@test "n2st::snow_splash › default" {
  run n2st::snow_splash
  assert_output --partial "NorLab"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "https://github.com/norlab-ulaval"

#  n2st::snow_splash >&3
}

@test "n2st::snow_splash › custom" {
  local TEST_NAME="Test name"
  local TEST_URL="https://github.com/test-name"
  run n2st::snow_splash "$TEST_NAME" "$TEST_URL"
  assert_output --partial "$TEST_NAME"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "$TEST_URL"
}

@test "n2st::snow_splash › teamcity case" {
  IS_TEAMCITY_RUN=true

  run n2st::snow_splash
  assert_line --index 2 --regexp "\["2m.*"\["0m
  assert_output --regexp "\["1m.*"NorLab".*"\["0m
  assert_output --regexp "\["2m.*"https://norlab.ulaval.ca".*"\["0m
}

# ----n2st::norlab_splash--------------------------------------------------------------------------------
@test "n2st::norlab_splash › default (negative)" {
  run n2st::norlab_splash
  assert_output --partial "NorLab"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "https://github.com/norlab-ulaval"

#  n2st::norlab_splash  >&3
}

@test "n2st::norlab_splash › custom" {
  local TEST_NAME="Test name"
  local TEST_URL="https://github.com/test-name"
  run n2st::norlab_splash "$TEST_NAME" "$TEST_URL"
  assert_output --partial "$TEST_NAME"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "$TEST_URL"
}

@test "n2st::norlab_splash › splash types small" {
  local TEST_NAME="Test name"
  local TEST_URL="https://github.com/test-name"
  run n2st::norlab_splash "$TEST_NAME" "$TEST_URL" 'small'
  assert_output --partial "$TEST_NAME"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "$TEST_URL"

#  n2st::norlab_splash "$TEST_NAME" "$TEST_URL" 'small' >&3
}

@test "n2st::norlab_splash › splash types big" {
  local TEST_NAME="Test name"
  local TEST_URL="https://github.com/test-name"
  run n2st::norlab_splash "$TEST_NAME" "$TEST_URL" 'big'
  assert_output --partial "$TEST_NAME"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "$TEST_URL"

#  n2st::norlab_splash "$TEST_NAME" "$TEST_URL" 'big' >&3
}

@test "n2st::norlab_splash › teamcity case" {
  IS_TEAMCITY_RUN=true

  run n2st::norlab_splash
  assert_line --index 2 --regexp "\["2m.*"\["0m
  assert_output --regexp "\["1m.*"NorLab".*"\["0m
  assert_output --regexp "\["2m.*"https://norlab.ulaval.ca".*"\["0m
}

# ====legacy API support testing===================================================================

@test "(legacy API support testing) echo_centering_str › expect pass" {
  local CENTERED_STR="Test me"
  local THE_STYLE="\033[1m"
  local THE_PAD_CHAR="."

  run echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR"
  assert_success
  assert_output --partial "$CENTERED_STR"
  assert_output --partial "$THE_PAD_CHAR"

  run echo_centering_str "$CENTERED_STR" "$THE_STYLE" "$THE_PAD_CHAR" "+++" "---"
  assert_success
  assert_output --partial "$CENTERED_STR"
  assert_output --partial "$THE_PAD_CHAR"
  assert_output --partial "+++"
  assert_output --partial "---"
}


@test "(legacy API support testing) snow_splash › custom" {
  local TEST_NAME="Test name"
  local TEST_URL="https://github.com/test-name"
  run snow_splash "$TEST_NAME" "$TEST_URL"
  assert_output --partial "$TEST_NAME"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "$TEST_URL"
}


@test "(legacy API support testing) norlab_splash › custom" {
  local TEST_NAME="Test name"
  local TEST_URL="https://github.com/test-name"
  run norlab_splash "$TEST_NAME" "$TEST_URL"
  assert_output --partial "$TEST_NAME"
  assert_output --partial "https://norlab.ulaval.ca"
  assert_output --partial "$TEST_URL"
}
