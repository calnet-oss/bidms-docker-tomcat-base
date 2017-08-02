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
# appears the Debian stretch tomcat package is missing this dependency.
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

COPY tmp_passwords/ /tmp/tmp_passwords/
COPY tmp_tomcat/ /tmp/tmp_tomcat/

# Add tomcat manager and manager-script users.
# manager is for the HTML GUI and manager-script is for deployment of apps.
RUN sed -i 's/<\/tomcat-users>/  <role rolename="manager-gui"\/>\n  <role rolename="manager-script"\/>\n  <role rolename="manager-jmx"\/>\n  <role rolename="manager-status"\/>\n  <role rolename="admin-gui"\/>\n  <role rolename="admin-script"\/>\n/' /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo -n '  <user username="manager" password="' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && cat /tmp/tmp_passwords/tomcat_manager_pw >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '" roles="manager-gui"/>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo -n '  <user username="manager-script" password="' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && cat /tmp/tmp_passwords/tomcat_manager-script_pw >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '" roles="manager-script"/>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '</tomcat-users>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml

# Generate a self-signed key pair for TLS
RUN mkdir /var/lib/tomcat${TOMCAT_VERSION}/certs \
  && keytool -genkey -alias tomcat -keyalg RSA -keysize 4096 \
       -validity 10000 \
       -storepass "changeit" -keypass "changeit" \
       -dname "CN=localhost,OU=BIDMS Tomcat Docker Dev" \
       -keystore /var/lib/tomcat${TOMCAT_VERSION}/certs/tomcat.jks \
  && chmod 600 /var/lib/tomcat${TOMCAT_VERSION}/certs/tomcat.jks \
  && chown tomcat${TOMCAT_VERSION}:tomcat${TOMCAT_VERSION} \
       /var/lib/tomcat${TOMCAT_VERSION}/certs/tomcat.jks

# Only user and group readable because of the JNDI secrets in server.xml.
# This fine is installed as root and tomcat is the group, so it has to be
# group readable.
RUN chmod 640 /etc/tomcat${TOMCAT_VERSION}/server.xml

# Add the JNDI resource for the BIDMS database connection pool
RUN sed -f /tmp/tmp_tomcat/globalnaming_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/server.xml

# Add the different TLS port numbers, each pointing to a different webapps
# base directory.  This gives more flexibility to protect applications
# running on different ports differently, such as with a firewall.
RUN mkdir \
      /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-user-frontend \
      /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-admin-frontend \
      /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-restapi-frontend \
      /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-backend \
      /var/lib/tomcat${TOMCAT_VERSION}/webapps-amq \
  && chown tomcat${TOMCAT_VERSION}:tomcat${TOMCAT_VERSION} \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-user-frontend \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-admin-frontend \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-restapi-frontend \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-backend \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-amq \
  && ln -fs /usr/share/tomcat8-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-user-frontend/manager \
  && ln -fs /usr/share/tomcat8-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-admin-frontend/manager \
  && ln -fs /usr/share/tomcat8-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-restapi-frontend/manager \
  && ln -fs /usr/share/tomcat8-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-bidms-backend/manager \
  && ln -fs /usr/share/tomcat8-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/webapps-amq/manager \
  && sed -f /tmp/tmp_tomcat/server_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/server.xml

RUN rm -rf /core /tmp/tmp_passwords /tmp/tmp_tomcat

# webapps-bidms-user-frontend
EXPOSE 8540
# webapps-bidms-admin-frontend
EXPOSE 8541
# webapps-bidms-restapi-frontend
EXPOSE 8542
# webapps-bidms-backend
EXPOSE 8543
# webapps-amq
EXPOSE 8544

COPY etc/container/ /etc/container/
ENTRYPOINT ["/etc/container/tomcat-entrypoint.sh", "interactive"]

# Use 'docker inspect <name>' to find the volume files on the host.
# <name> is the value of the --name parameter when invoking docker run.
VOLUME /var/lib/tomcat${TOMCAT_VERSION}
