#!/usr/bin/env bash

gem search "^${1}$" --remote --all \
  | grep -o '\((.*)\)$' \
  | tr -d '() ' \
  | tr ',' "\n" \
  | sort
