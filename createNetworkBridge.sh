#!/bin/sh

. ./config.env

if [ -z "$RUNTIME_CMD" ]; then
  RUNTIME_CMD=docker
fi

$RUNTIME_CMD network create --driver bridge bidms_nw
