#!/bin/bash

#
# Copyright (c) 2017, Regents of the University of California and
# contributors.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 

function check_exit {
  error_code=$?
  if [ $error_code != 0 ]; then
    echo "ERROR: last command exited with an error code of $error_code"
    exit $error_code
  fi
}

if [ ! -z "$CONFIG_FILE" ]; then
  if [ ! -f $CONFIG_FILE ]; then
    echo "$CONFIG_FILE does not exist as a file"
    exit 1
  fi
elif [ -f ./config.env ]; then
  CONFIG_FILE=./config.env
elif [ -f ./config.env.template ]; then
  cat << EOF
Warning: There is no config.env file.  It is recommended you copy
config.env.template to config.env and edit it before running this, otherwise
I'm assuming you want the defaults from config.env.template.
EOF
  CONFIG_FILE=./config.env.template
else
  echo "There is no config.env file nor a config.env.template fallback.  Can't continue."
  exit 1
fi

echo "Using config values from $CONFIG_FILE"
. $CONFIG_FILE || check_exit

if [ -z "$RUNTIME_CMD" ]; then
  # Can be overriden in config.env to be podman instead.
  RUNTIME_CMD=docker
fi

if [ ! -z "$NETWORK" -a "$BUILDTIME_CMD" != "podman" ]; then
  echo "NETWORK=$NETWORK"
  NETWORKPARAMS+="--network $NETWORK "
else
  echo "ERROR: Required NETWORK value missing from $CONFIG_FILE"
  exit 1
fi

if [ ! -z "$LOCAL_BIDMS_USER_FRONTEND_TOMCAT_PORT" ]; then
  echo "LOCAL_BIDMS_USER_FRONTEND_TOMCAT_PORT=$LOCAL_BIDMS_USER_FRONTEND_TOMCAT_PORT"
else
  echo "ERROR: Required LOCAL_BIDMS_USER_FRONTEND_TOMCAT_PORT value missing from $CONFIG_FILE"
  exit 1
fi
if [ ! -z "$LOCAL_BIDMS_ADMIN_FRONTEND_TOMCAT_PORT" ]; then
  echo "LOCAL_BIDMS_ADMIN_FRONTEND_TOMCAT_PORT=$LOCAL_BIDMS_ADMIN_FRONTEND_TOMCAT_PORT"
else
  echo "ERROR: Required LOCAL_BIDMS_ADMIN_FRONTEND_TOMCAT_PORT value missing from $CONFIG_FILE"
  exit 1
fi
if [ ! -z "$LOCAL_BIDMS_RESTAPI_FRONTEND_TOMCAT_PORT" ]; then
  echo "LOCAL_BIDMS_RESTAPI_FRONTEND_TOMCAT_PORT=$LOCAL_BIDMS_RESTAPI_FRONTEND_TOMCAT_PORT"
else
  echo "ERROR: Required LOCAL_BIDMS_RESTAPI_FRONTEND_TOMCAT_PORT value missing from $CONFIG_FILE"
  exit 1
fi
if [ ! -z "$LOCAL_BIDMS_BACKEND_TOMCAT_PORT" ]; then
  echo "LOCAL_BIDMS_BACKEND_TOMCAT_PORT=$LOCAL_BIDMS_BACKEND_TOMCAT_PORT"
else
  echo "ERROR: Required LOCAL_BIDMS_BACKEND_TOMCAT_PORT value missing from $CONFIG_FILE"
  exit 1
fi
if [ ! -z "$LOCAL_AMQ_TOMCAT_PORT" ]; then
  echo "LOCAL_AMQ_TOMCAT_PORT=$LOCAL_AMQ_TOMCAT_PORT"
else
  echo "ERROR: Required LOCAL_AMQ_TOMCAT_PORT value missing from $CONFIG_FILE"
  exit 1
fi
if [ ! -z "$LOCAL_AMQ_OPENWIRE_SSL_PORT" ]; then
  echo "LOCAL_AMQ_OPENWIRE_SSL_PORT=$LOCAL_AMQ_OPENWIRE_SSL_PORT"
else
  echo "ERROR: Required LOCAL_AMQ_OPENWIRE_SSL_PORT value missing from $CONFIG_FILE"
  exit 1
fi
# Optional
if [ ! -z "$LOCAL_JVM_DEBUG_PORT" ]; then
  echo "LOCAL_JVM_DEBUG_PORT=$LOCAL_JVM_DEBUG_PORT"
fi

if [[ -z "$NO_HOST_TOMCAT_DIRECTORY" && ! -z "$HOST_TOMCAT_DIRECTORY" ]]; then
  echo "HOST_TOMCAT_DIRECTORY=$HOST_TOMCAT_DIRECTORY"
  MOUNTPARAMS="-v $HOST_TOMCAT_DIRECTORY:/var/lib/tomcat10"
else
  # Docker will choose where it wants to put it on the host.
  # Use docker inspect bidms-tomcat to find out where.
  echo "HOST_TOMCAT_DIRECTORY not set.  Using container default."
fi

if [[ -z "$NO_INTERACTIVE" && -z "$INTERACTIVE_PARAMS" ]]; then
  INTERACTIVE_PARAMS="-ti"
elif [ ! -z "$NO_INTERACTIVE" ]; then
  INTERACTIVE_PARAMS="-d --entrypoint /etc/container/tomcat-entrypoint.sh"
  ENTRYPOINT_ARGS="detached"
fi

OPTIONAL_PORT_OPTS=""
if [ ! -z "$LOCAL_JVM_DEBUG_PORT" ]; then
  OPTIONAL_PORT_OPTS+="-p $LOCAL_JVM_DEBUG_PORT:4782"
fi

# SYS_PTRACE capability necessary for /etc/init.d/tomcat script, which uses
# start-stop-daemon, which needs /proc/<pid>/exe to match a PID with --exec,
# and SYS_PTRACE needed for /proc/<pid>/exe.
$RUNTIME_CMD run $INTERACTIVE_PARAMS --rm --name "bidms-tomcat" \
  $MOUNTPARAMS \
  $NETWORKPARAMS \
  -p $LOCAL_BIDMS_USER_FRONTEND_TOMCAT_PORT:8540 \
  -p $LOCAL_BIDMS_ADMIN_FRONTEND_TOMCAT_PORT:8541 \
  -p $LOCAL_BIDMS_RESTAPI_FRONTEND_TOMCAT_PORT:8542 \
  -p $LOCAL_BIDMS_BACKEND_TOMCAT_PORT:8543 \
  -p $LOCAL_AMQ_TOMCAT_PORT:8544 \
  -p $LOCAL_AMQ_OPENWIRE_SSL_PORT:61617 \
  $OPTIONAL_PORT_OPTS \
  --cap-add=SYS_PTRACE \
  $* \
  bidms/tomcat:tomcat10 \
  $ENTRYPOINT_ARGS || check_exit

if [ ! -z "$NO_INTERACTIVE" ]; then
  echo "Running in detached mode.  Stop the container with '$RUNTIME_CMD stop bidms-tomcat'."
fi
