#!/bin/bash

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

QUESTION_FLAG="${GREEN}?${RESET}"
WARNING_FLAG="${YELLOW}!${RESET}"
NOTICE_FLAG="${CYAN}❯${RESET}"

echo_notice() {
  echo -e "$NOTICE_FLAG $CYAN $1$RESET"
}

echo_prompt() {
  local PROMPT
  local HINT
  PROMPT=$1; shift
  HINT=$1; shift
  echo -ne "$QUESTION_FLAG $CYAN $PROMPT $WHITE$HINT$CYAN: $WHITE" > /dev/stderr
  read -r CHOICE
  echo -en "$CHOICE"
  echo_reset > /dev/stderr
}

echo_warning() {
  echo -e "$WARNING_FLAG $YELLOW $1$RESET"
}

echo_reset() {
  echo -en "$RESET"
}

exit_if_dirty() {
  if [[ $(git diff --stat) != '' ]]; then
    echo_warning "You have uncommitted changes. Please resolve your changes first."
    exit 1
  fi
}
