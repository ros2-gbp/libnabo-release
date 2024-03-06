#!/bin/bash

function assert_empty(){
  assert [ -z "${1}" ]
}

function assert_not_empty(){
  assert [ ! -z "${1}" ]
}

function _bats_run_env_variable_string(){
  local MSG_DIMMED_FORMAT="\033[1;2m"
  local MSG_END_FORMAT="\033[0m"
  BREV_STR="››››››
${MSG_DIMMED_FORMAT}Status=${MSG_END_FORMAT}${status}
${MSG_DIMMED_FORMAT}output=${MSG_END_FORMAT}${output}
${MSG_DIMMED_FORMAT}BATS_RUN_COMMAND=${MSG_END_FORMAT}${BATS_RUN_COMMAND}
‹‹‹‹‹‹"
#${MSG_DIMMED_FORMAT}lines=${MSG_END_FORMAT}${lines[*]}
}

function bats_print_run_env_variable_on_error(){
  _bats_run_env_variable_string
  echo -e "${BREV_STR}"
}

function bats_print_run_env_variable(){
  _bats_run_env_variable_string
  echo -e "${BREV_STR}" >&3
}

function mock_docker_command_exit_ok() {
    function docker() {
      return 0
    }
}

function mock_docker_command_exit_error() {
    function docker() {
      echo "Error" 1>&2
      return 1
    }
}

function fake_IS_TEAMCITY_RUN() {
    if [[ ! ${TEAMCITY_VERSION} ]]; then
        TEAMCITY_VERSION=fake
    fi
}
