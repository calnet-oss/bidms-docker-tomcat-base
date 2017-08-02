#!/bin/bash

CONTAINER_DIR="/var/lib/tomcat8"
INSPECT=$(docker inspect bidms-tomcat | sed -e '/Source/,/Destination/!d')

while read -ra arr; do
  if [ "${arr[0]}" == '"Source":' ]; then
    src=${arr[1]}
  elif [[ "${arr[0]}" == '"Destination":' && "${arr[1]}" == "\"$CONTAINER_DIR\"," ]]; then
    tomcat_src=$src
  fi
done  <<< "$INSPECT"
tomcat_src=$(echo $tomcat_src|cut -d'"' -f2)

echo $tomcat_src
