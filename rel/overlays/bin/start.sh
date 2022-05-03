#!/usr/bin/env bash
set -ex

sudo /sbin/docker-setup
export DOCKER_HOST="tcp://0.0.0.0:2375"
bin/utility start
