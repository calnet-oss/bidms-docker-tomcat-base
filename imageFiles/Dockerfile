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
FROM bidms/debian_base

ARG APT_PROXY_URL=
RUN if [ ! -z "$APT_PROXY_URL" ]; then echo "Acquire::http::Proxy \"$APT_PROXY_URL\";" > /etc/apt/apt.conf.d/00aptproxy; else echo "not using apt proxy"; fi

ARG TOMCAT_VERSION=8

# Installing a specific version of libservlet shouldn't be necessary as the
# servlet depdendencies should be attached to the tomcat package, but it
# appears the Debian stretch tomcat8 package is missing this dependency.
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y tomcat${TOMCAT_VERSION} \
       tomcat${TOMCAT_VERSION}-admin \
       libservlet3.1-java \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# Reverse the Tomcat logs and work symlinks that the intaller has placed: We
# want the logs and work to go into the mounted volume to retain persistence
# of these files.
RUN rm -rf /var/lib/tomcat${TOMCAT_VERSION}/logs /var/log/tomcat${TOMCAT_VERSION} \
      /var/lib/tomcat${TOMCAT_VERSION}/work /var/cache/tomcat${TOMCAT_VERSION} \
    && mkdir /var/lib/tomcat${TOMCAT_VERSION}/logs /var/lib/tomcat${TOMCAT_VERSION}/work \
    && chmod 755 /var/lib/tomcat${TOMCAT_VERSION}/logs /var/lib/tomcat${TOMCAT_VERSION}/work \
    && chown tomcat${TOMCAT_VERSION}:tomcat${TOMCAT_VERSION} /var/lib/tomcat${TOMCAT_VERSION}/logs /var/lib/tomcat${TOMCAT_VERSION}/work \
    && ln -fs /var/lib/tomcat${TOMCAT_VERSION}/logs /var/log/tomcat${TOMCAT_VERSION} \
    && ln -fs /var/lib/tomcat${TOMCAT_VERSION}/work /var/cache/tomcat${TOMCAT_VERSION}

# There's a problem with the Debian stretch tomcat package where the
# tomcat user does not have permission to create the PID file in /var/run,
# so we have to create a separate run directory owned by the tomcat user and
# force the start-up script to use it.
#RUN mkdir /var/run/tomcat${TOMCAT_VERSION} \
#  && chown tomcat${TOMCAT_VERSION}:tomcat${TOMCAT_VERSION} /var/run/tomcat${TOMCAT_VERSION} \
#  && sed -i "s#CATALINA_PID=\"/var/run/\$NAME.pid\"#CATALINA_PID=\"/var/run/tomcat${TOMCAT_VERSION}/\$NAME.pid\"#" /etc/init.d/tomcat8

COPY tmp_passwords/ /tmp/tmp_passwords/

# Add tomcat manager user
RUN sed -i 's/<\/tomcat-users>/  <role rolename="manager"\/>\n  <role rolename="manager-gui"\/>\n  <role rolename="manager-script"\/>\n  <role rolename="manager-jmx"\/>\n  <role rolename="manager-status"\/>\n/' /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo -n '  <user username="manager" password="' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && cat /tmp/tmp_passwords/tomcat_manager_pw >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '" roles="manager"/>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '</tomcat-users>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml

RUN rm -rf /core /tmp/tmp_passwords

EXPOSE 8080

COPY etc/container/ /etc/container/
ENTRYPOINT ["/etc/container/tomcat-entrypoint.sh", "interactive"]

# Use 'docker inspect <name>' to find the volume files on the host.
# <name> is the value of the --name parameter when invoking docker run.
VOLUME /var/lib/tomcat${TOMCAT_VERSION}
