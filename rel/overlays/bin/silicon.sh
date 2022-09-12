#!/usr/bin/env bash

set -e

function generate() {
  local code=$1; shift
  local theme=$1; shift
  local font=$1; shift
  local language_ext=$1; shift

  local tmpfile=$(mktemp --suffix='.png')

  echo "$code" | silicon -o "$tmpfile" --font "$font" -l ex
  echo "$tmpfile"
}

generate "$1" "$2" "$3" "$4"
