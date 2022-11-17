#!/usr/bin/env bash

set -e

function generate() {
  local code=$1; shift
  local theme=$1; shift
  local font=$1; shift
  local language_ext=$1; shift

  local tmpfile=$(mktemp "$TMPDIR/$(uuidgen)-XXXXXX.png")

  echo "$code" | silicon -o "$tmpfile" \
    --background '#7A12CE' \
    --font "$font" \
    --language ex \
    --pad-vert 40 \
    --pad-horiz 40
  echo "$tmpfile"
}

generate "$1" "$2" "$3" "$4"
