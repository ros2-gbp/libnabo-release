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
TESTED_FILE="prompt_utilities.bash"

setup_file() {
  BATS_DOCKER_WORKDIR=$(pwd) && export BATS_DOCKER_WORKDIR
#  pwd >&3 && tree -L 1 -a -hug >&3
#  printenv >&3
}

setup() {
  source .env.project
  cd "src/function_library" || exit 1
  source ./$TESTED_FILE
  TEST_TEMP_DIR="$(temp_make)"
}

# ====Teardown=====================================================================================

teardown() {
  bats_print_run_env_variable_on_error
}

#teardown_file() {
#    echo "executed once after finishing the last test"
#}

# ====Test casses==================================================================================

@test "sourcing $TESTED_FILE from bad cwd › expect fail" {
  cd "${BATS_DOCKER_WORKDIR}/src/"
  # Note:
  #  - "echo 'Y'" is for sending an keyboard input to the 'read' command which expect a single character
  #    run bash -c "echo 'Y' | source ./function_library/$TESTED_FILE"
  #  - Alt: Use the 'yes [n]' command which optionaly send n time
  run bash -c "yes 1 | source ./function_library/$TESTED_FILE"
  assert_failure 1
  assert_output --partial "'$TESTED_FILE' script must be sourced from"
#  bats_print_run_env_variable
}

@test "sourcing $TESTED_FILE from ok cwd › expect pass" {
  assert_not_empty "$PROJECT_GIT_NAME"
  cd "${BATS_DOCKER_WORKDIR}/src/function_library/"
  run bash -c "PROJECT_GIT_NAME=$PROJECT_GIT_NAME && source ./$TESTED_FILE"
  assert_success
}


@test "env variable fetching ok" {
  # Note: refer to 'test_dotenv_files.bats' for env variable test logic

  #printenv | grep -i -e MSG_ -e PROJECT_  >&3

  assert_empty "$PROJECT_PROMPT_NAME"
  assert_not_empty "$PROJECT_GIT_NAME"
  assert_not_empty "$MSG_PROMPT_NAME"
}

@test "all n2st::print_msg functions ok" {
    local TEST_MSG='test message'

    run n2st::print_msg "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"


    run n2st::print_msg_done "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"
    assert_output --partial "done"

    run n2st::print_msg_warning "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"
    assert_output --partial "warning"

    run n2st::print_msg_awaiting_input "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"
    assert_output --partial "awaiting input"
}

@test "all n2st::print_msg_error_and_exit functions ok" {
    local TEST_MSG='test error message'

    run n2st::print_msg_error_and_exit "$TEST_MSG"
    assert_output --partial "$TEST_MSG"
    assert_output --partial "error"
    assert_failure 1

    run n2st::print_msg_error "$TEST_MSG"
    assert_output --partial "$TEST_MSG"
    assert_output --partial "error"
    assert_success
}

@test "n2st::draw_horizontal_line_across_the_terminal_window ok" {
#    printenv | grep -i -e 'TERM' -e 'TPUT'  -e 'COLUMNS' >&3
#    n2st::draw_horizontal_line_across_the_terminal_window "=" >&3
#    tput longname >&3

    run n2st::draw_horizontal_line_across_the_terminal_window
    assert_success

    run n2st::draw_horizontal_line_across_the_terminal_window '.'
    assert_success
    assert_output --partial "....."

    run n2st::draw_horizontal_line_across_the_terminal_window ':'
    assert_success
    assert_output --partial ":::::"

    TERM=dumb
    run n2st::draw_horizontal_line_across_the_terminal_window
    assert_success
    assert_output --partial "====="

    unset TERM
    run n2st::draw_horizontal_line_across_the_terminal_window
    assert_success
    assert_output --partial "====="
}

@test "n2st::print_formated_script_header ok" {
    local MAIN_MSG="Starting"
    local SCRIPT_NAME="Script name"

    run n2st::print_formated_script_header
    assert_success
    assert_line --index 0 --partial "="
    assert_line --index 1 --partial "$MAIN_MSG"

    run n2st::print_formated_script_header "$SCRIPT_NAME" ':'
    assert_line --index 0 --partial ":::"
    assert_line --index 1 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "$SCRIPT_NAME"
    assert_success
}

@test "n2st::print_formated_script_footer ok" {
    local MAIN_MSG="Completed"
    local SCRIPT_NAME="Script name"

    run n2st::print_formated_script_footer
    assert_success
    assert_line --index 0 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "="

    run n2st::print_formated_script_footer "$SCRIPT_NAME" ':'
    assert_line --index 0 --partial "$MAIN_MSG"
    assert_line --index 0 --partial "$SCRIPT_NAME"
    assert_line --index 1 --partial ":::"
    assert_success
}

@test "n2st::print_formated_back_to_script_msg ok" {
    local MAIN_MSG="Back to "
    local SCRIPT_NAME="Script name"

    run n2st::print_formated_back_to_script_msg
    assert_success
    assert_line --index 0 --partial "="
    assert_line --index 1 --partial "$MAIN_MSG"

    run n2st::print_formated_back_to_script_msg "$SCRIPT_NAME" ':'
    assert_line --index 0 --partial ":::"
    assert_line --index 1 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "$SCRIPT_NAME"
    assert_success
}

@test "print_formated_file_preview ok" {
    local MAIN_MSG="EOF"
    local SCRIPT_NAME="Test message"

    run n2st::print_formated_file_preview_begin "$SCRIPT_NAME"
    assert_success
    assert_line --index 1 --partial "."
    assert_line --index 2 --partial "$MAIN_MSG"
    assert_line --index 2 --partial "$SCRIPT_NAME"

    run n2st::print_formated_file_preview_end
    assert_line --index 0 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "."
    assert_success
}

@test "n2st::preview_file_in_promt ok" {
  local TMP_TEST_FILE="${cwdTEST_TEMP_DIR}/.env.tmp_test_file"
  touch "$TMP_TEST_FILE"

  (
      echo
      echo "Test message"
      echo
    ) >> "$TMP_TEST_FILE"

  run n2st::preview_file_in_promt "$TMP_TEST_FILE"
  assert_success
  assert_output --partial "Test message"
#  bats_print_run_env_variable
}

# ====legacy API support testing===================================================================

@test "(legacy API support testing) all print_msg functions ok" {
    local TEST_MSG='test message'

    run print_msg "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"


    run print_msg_done "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"
    assert_output --partial "done"

    run print_msg_warning "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"
    assert_output --partial "warning"

    run print_msg_awaiting_input "$TEST_MSG"
    assert_success
    assert_output --partial "$TEST_MSG"
    assert_output --partial "awaiting input"
}

@test "(legacy API support testing) all print_msg_error_and_exit functions ok" {
    local TEST_MSG='test error message'

    run print_msg_error_and_exit "$TEST_MSG"
    assert_output --partial "$TEST_MSG"
    assert_output --partial "error"
    assert_failure 1

    run print_msg_error "$TEST_MSG"
    assert_output --partial "$TEST_MSG"
    assert_output --partial "error"
    assert_success
}

@test "(legacy API support testing) draw_horizontal_line_across_the_terminal_window ok" {
#    printenv | grep -i -e 'TERM' -e 'TPUT'  -e 'COLUMNS' >&3
#    draw_horizontal_line_across_the_terminal_window "=" >&3
#    tput longname >&3

    run draw_horizontal_line_across_the_terminal_window
    assert_success

    run draw_horizontal_line_across_the_terminal_window '.'
    assert_success
    assert_output --partial "....."

    run draw_horizontal_line_across_the_terminal_window ':'
    assert_success
    assert_output --partial ":::::"

    TERM=dumb
    run draw_horizontal_line_across_the_terminal_window
    assert_success
    assert_output --partial "====="

    unset TERM
    run draw_horizontal_line_across_the_terminal_window
    assert_success
    assert_output --partial "====="
}

@test "(legacy API support testing) print_formated_script_header ok" {
    local MAIN_MSG="Starting"
    local SCRIPT_NAME="Script name"

    run print_formated_script_header
    assert_success
    assert_line --index 0 --partial "="
    assert_line --index 1 --partial "$MAIN_MSG"

    run print_formated_script_header "$SCRIPT_NAME" ':'
    assert_line --index 0 --partial ":::"
    assert_line --index 1 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "$SCRIPT_NAME"
    assert_success
}

@test "(legacy API support testing) print_formated_script_footer ok" {
    local MAIN_MSG="Completed"
    local SCRIPT_NAME="Script name"

    run print_formated_script_footer
    assert_success
    assert_line --index 0 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "="

    run print_formated_script_footer "$SCRIPT_NAME" ':'
    assert_line --index 0 --partial "$MAIN_MSG"
    assert_line --index 0 --partial "$SCRIPT_NAME"
    assert_line --index 1 --partial ":::"
    assert_success
}

@test "(legacy API support testing) print_formated_back_to_script_msg ok" {
    local MAIN_MSG="Back to "
    local SCRIPT_NAME="Script name"

    run print_formated_back_to_script_msg
    assert_success
    assert_line --index 0 --partial "="
    assert_line --index 1 --partial "$MAIN_MSG"

    run print_formated_back_to_script_msg "$SCRIPT_NAME" ':'
    assert_line --index 0 --partial ":::"
    assert_line --index 1 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "$SCRIPT_NAME"
    assert_success
}

@test "(legacy API support testing) print_formated_file_preview ok" {
    local MAIN_MSG="EOF"
    local SCRIPT_NAME="Test message"

    run print_formated_file_preview_begin "$SCRIPT_NAME"
    assert_success
    assert_line --index 1 --partial "."
    assert_line --index 2 --partial "$MAIN_MSG"
    assert_line --index 2 --partial "$SCRIPT_NAME"

    run print_formated_file_preview_end
    assert_line --index 0 --partial "$MAIN_MSG"
    assert_line --index 1 --partial "."
    assert_success
}

@test "(legacy API support testing) preview_file_in_promt ok" {
  local TMP_TEST_FILE="${cwdTEST_TEMP_DIR}/.env.tmp_test_file"
  touch "$TMP_TEST_FILE"

  (
      echo
      echo "Test message"
      echo
    ) >> "$TMP_TEST_FILE"

  run preview_file_in_promt "$TMP_TEST_FILE"
  assert_success
  assert_output --partial "Test message"
#  bats_print_run_env_variable
}
