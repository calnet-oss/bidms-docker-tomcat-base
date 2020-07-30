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
  if [ -e /var/lib/tomcat9/shuttingdown ]; then
    rm /var/lib/tomcat9/shuttingdown
  fi
  if [ -e /var/lib/tomcat9/cleanshutdown ]; then
    rm /var/lib/tomcat9/cleanshutdown
  fi
  /usr/sbin/syslogd
  
  CATALINA_HOME=/usr/share/tomcat9 \
  CATALINA_BASE=/var/lib/tomcat9 \
  CATALINA_TMPDIR=/tmp \
  /usr/libexec/tomcat9/tomcat-update-policy.sh \
    && sudo \
         CATALINA_HOME=/usr/share/tomcat9 \
         CATALINA_BASE=/var/lib/tomcat9 \
         CATALINA_TMPDIR=/tmp \
         -u tomcat /usr/libexec/tomcat9/tomcat-start.sh &
}

function container_shutdown {
  touch /var/lib/tomcat9/shuttingdown
  sudo \
    CATALINA_HOME=/usr/share/tomcat9 \
    CATALINA_BASE=/var/lib/tomcat9 \
    CATALINA_TMPDIR=/tmp \
    -u tomcat /usr/share/tomcat9/bin/shutdown.sh
  kill -TERM $(cat /var/run/syslog.pid)
  echo "Processes still running after shutdown:" > /var/lib/tomcat9/cleanshutdown
  ps -uxaw >> /var/lib/tomcat9/cleanshutdown
  rm /var/lib/tomcat9/shuttingdown
  exit
}
