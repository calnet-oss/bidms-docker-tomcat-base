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

function container_startup {
  if [ -e /var/lib/tomcat10/shuttingdown ]; then
    rm /var/lib/tomcat10/shuttingdown
  fi
  if [ -e /var/lib/tomcat10/cleanshutdown ]; then
    rm /var/lib/tomcat10/cleanshutdown
  fi
  update_resolvconf
  /usr/sbin/syslogd
  
  CATALINA_HOME=/usr/share/tomcat10 \
  CATALINA_BASE=/var/lib/tomcat10 \
  CATALINA_TMPDIR=/tmp \
  JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
  /usr/libexec/tomcat10/tomcat-update-policy.sh \
    && sudo \
         CATALINA_HOME=/usr/share/tomcat10 \
         CATALINA_BASE=/var/lib/tomcat10 \
         CATALINA_TMPDIR=/tmp \
         JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
         -u tomcat /usr/libexec/tomcat10/tomcat-start.sh &
}

function container_shutdown {
  touch /var/lib/tomcat10/shuttingdown
  sudo \
    CATALINA_HOME=/usr/share/tomcat10 \
    CATALINA_BASE=/var/lib/tomcat10 \
    CATALINA_TMPDIR=/tmp \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    -u tomcat /usr/share/tomcat10/bin/shutdown.sh
  kill -TERM $(cat /var/run/syslog.pid)
  echo "Processes still running after shutdown:" > /var/lib/tomcat10/cleanshutdown
  ps -uxaw >> /var/lib/tomcat10/cleanshutdown
  rm /var/lib/tomcat10/shuttingdown
  exit
}

# Optionally rebuild /etc/resolv.conf at runtime if DNS_SEARCH and/or
# DNS_NAMESERVERS variables are present in the environment.
# /etc/resolv.conf is not touched if both of these environment variables are
# not present.  DNS_NAMESERVERS AND DNS_SEARCH are both space delimited.
function update_resolvconf {
  RESULT=()
  
  if [ ! -z "$DNS_SEARCH" ]; then
    RESULT+=("search $DNS_SEARCH")
  fi
  
  if [ ! -z "$DNS_NAMESERVERS" ]; then
    for i in $(echo $DNS_NAMESERVERS)
    do
      RESULT+=("nameserver $i")
    done
  fi
  
  if [ ${#RESULT[@]} -gt 0 ]; then
    for i in "${!RESULT[@]}"; do
      if [ $i -eq 0 ]; then
        echo "${RESULT[$i]}" > /tmp/resolv.conf
      else
        echo "${RESULT[$i]}" >> /tmp/resolv.conf
      fi
    done
    chown 644 /tmp/resolv.conf
    mv /tmp/resolv.conf /etc
  fi
}
