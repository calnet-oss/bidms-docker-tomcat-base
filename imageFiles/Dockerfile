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
FROM bidms/debian_base:bookworm

ARG APT_PROXY_URL=
RUN if [ ! -z "$APT_PROXY_URL" ]; then echo "Acquire::http::Proxy \"$APT_PROXY_URL\";" > /etc/apt/apt.conf.d/00aptproxy; else echo "not using apt proxy"; fi

ARG TOMCAT_VERSION=10

RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y tomcat${TOMCAT_VERSION} \
       tomcat${TOMCAT_VERSION}-admin \
       openjdk-17-jdk-headless openjdk-11-jdk-headless- default-jre-headless- \
       telnet dnsutils git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# Change tomcat's home directory
RUN usermod --home /var/lib/tomcat${TOMCAT_VERSION} tomcat

# Reverse the Tomcat logs and work symlinks that the intaller has placed: We
# want the logs and work to go into the mounted volume to retain persistence
# of these files.
RUN rm -rf /var/lib/tomcat${TOMCAT_VERSION}/logs /var/log/tomcat${TOMCAT_VERSION} \
      /var/lib/tomcat${TOMCAT_VERSION}/work /var/cache/tomcat${TOMCAT_VERSION} \
    && mkdir /var/lib/tomcat${TOMCAT_VERSION}/logs /var/lib/tomcat${TOMCAT_VERSION}/work \
    && chmod 755 /var/lib/tomcat${TOMCAT_VERSION}/logs /var/lib/tomcat${TOMCAT_VERSION}/work \
    && chown tomcat:tomcat /var/lib/tomcat${TOMCAT_VERSION}/logs /var/lib/tomcat${TOMCAT_VERSION}/work \
    && ln -fs /var/lib/tomcat${TOMCAT_VERSION}/logs /var/log/tomcat${TOMCAT_VERSION} \
    && ln -fs /var/lib/tomcat${TOMCAT_VERSION}/work /var/cache/tomcat${TOMCAT_VERSION}

COPY tmp_passwords/ /tmp/tmp_passwords/
COPY tmp_tomcat/ /tmp/tmp_tomcat/

# Add tomcat manager, manager-script and amq-admin users.
# manager is for the HTML GUI and manager-script is for deployment of apps.
# amq-admin is for the ActiveMQ Webconsole, if it's deployed.  The
# activemq-broker-and-webconsole-overlay-war project uses "amq-admin" as the
# role in its web.xml file.
RUN sed -i 's/<\/tomcat-users>/  <role rolename="manager-gui"\/>\n  <role rolename="manager-script"\/>\n  <role rolename="manager-jmx"\/>\n  <role rolename="manager-status"\/>\n  <role rolename="admin-gui"\/>\n  <role rolename="admin-script"\/>\n  <role rolename="amq-admin"\/>\n/' /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo -n '  <user username="manager" password="' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && cat /tmp/tmp_passwords/tomcat_manager_pw >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '" roles="manager-gui"/>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo -n '  <user username="manager-script" password="' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && cat /tmp/tmp_passwords/tomcat_manager-script_pw >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '" roles="manager-script"/>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo -n '  <user username="amq-admin" password="' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && cat /tmp/tmp_passwords/tomcat_amq-admin_pw >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '" roles="amq-admin"/>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml \
  && echo '</tomcat-users>' >> /etc/tomcat${TOMCAT_VERSION}/tomcat-users.xml

# Copy the keystore for TLS
RUN mkdir /var/lib/tomcat${TOMCAT_VERSION}/certs
COPY tmp_tomcat/tomcat.jks /var/lib/tomcat${TOMCAT_VERSION}/certs
COPY tmp_tomcat/tomcat_pubkey.pem /var/lib/tomcat${TOMCAT_VERSION}/certs
RUN chmod 640 /var/lib/tomcat${TOMCAT_VERSION}/certs/tomcat.jks \
  && chgrp tomcat \
       /var/lib/tomcat${TOMCAT_VERSION}/certs/tomcat.jks \
       /var/lib/tomcat${TOMCAT_VERSION}/certs/tomcat_pubkey.pem

RUN sed -i 's#directory="logs"#directory="${catalina.logdir}"#' /etc/tomcat${TOMCAT_VERSION}/server.xml
RUN sed -i 's#Server port="-1" shutdown="SHUTDOWN"#Server port="8005" shutdown="SHUTDOWN"#' /etc/tomcat${TOMCAT_VERSION}/server.xml

# Add the JNDI resource for the BIDMS database connection pool
ARG JNDI_DB_URL=jdbc:postgresql://db1:5432/registry?ssl=true&amp;sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory
RUN sed -f /tmp/tmp_tomcat/globalnaming_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/server.xml \
  && sed -i "s#JNDI_DB_URL#$JNDI_DB_URL#" /etc/tomcat${TOMCAT_VERSION}/server.xml

# Replace the JNDI database password
RUN /tmp/tmp_passwords/replaceString.pl /tmp/tmp_passwords/bidms_db_registry_pw /etc/tomcat${TOMCAT_VERSION}/server.xml BIDMS_DB_REG_PW \
        > /tmp/server.xml \
  && mv /tmp/server.xml /etc/tomcat${TOMCAT_VERSION}/server.xml \
  && chown root:tomcat /etc/tomcat${TOMCAT_VERSION}/server.xml \
  && chmod 640 /etc/tomcat${TOMCAT_VERSION}/server.xml

# Copy the jmx.access and jmx.password files
COPY tmp_passwords/jmx.access /var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.access
COPY tmp_passwords/jmx.password /var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.password
RUN chmod 640 /var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.access \
      && chown root:tomcat /var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.access \
      && chmod 600 /var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.password \
      && chown tomcat:tomcat /var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.password

# Add the different TLS port numbers, each pointing to a different webapps
# base directory.  This gives more flexibility to protect applications
# running on different ports differently, such as with a firewall.
RUN mkdir -p /var/lib/tomcat${TOMCAT_VERSION}/local-webapps \
  && mkdir \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-user-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsUserFrontend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-admin-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAdminFrontend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-restapi-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsRestapiFrontend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-backend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsBackend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/amq \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAMQ \
  && chown tomcat:tomcat \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-user-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsUserFrontend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-admin-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAdminFrontend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-restapi-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsRestapiFrontend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-backend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsBackend \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/amq \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAMQ \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-user-frontend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-admin-frontend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-restapi-frontend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/bidms-backend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /var/lib/tomcat${TOMCAT_VERSION}/local-webapps/amq/manager \
  && sed -f /tmp/tmp_tomcat/server_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/server.xml \
  && sed -f /tmp/tmp_tomcat/context_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/context.xml

# It's possible to override JAVA_MEM_OPTS and JAVA_DEBUG_OPTS at container
# runtime, as well as adding to JAVA_OPTS, by placing these environment
# variables in the
# /var/lib/tomcat${TOMCAT_VERSION}/catalina.env file.
ARG JAVA_MEM_OPTS="-Xmx2048m"
# Example JAVA_DEBUG_OPTS="-agentlib:jdwp=transport=dt_socket,address=4782,server=y,suspend=n"
ARG JAVA_DEBUG_OPTS=""
RUN (echo "\nGRAILS_ENV=development" \
  && echo "PODNAME=\$(if [ -f /podinfo/name ]; then cat /podinfo/name; fi)" \
  && echo "CATALINA_LOGDIR=\$(if [ -z \"\$PODNAME\" ]; then echo \"logs\"; else echo \"logs/\$PODNAME\"; fi)" \
  && echo "if [ ! -z \"\$PODNAME\" ]; then\n  if [ ! -d \"/var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}\" ]; then\n    mkdir /var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}\n    chown tomcat:tomcat /var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}\n  fi\n  CATALINA_OUT=\"/var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}/catalina.out\"\nfi" \
  && echo "PODNAME_OPT=\$(if [ ! -z \"\$PODNAME\" ]; then echo \"-Dcatalina.podname=\$PODNAME\"; fi)" \
  && echo "JAVA_MEM_OPTS=\"$JAVA_MEM_OPTS\"" \
  && echo "JAVA_DEBUG_OPTS=\"$JAVA_DEBUG_OPTS\"" \
  && echo "if [ -f /var/lib/tomcat${TOMCAT_VERSION}/catalina.env ]; then . /var/lib/tomcat${TOMCAT_VERSION}/catalina.env; fi" \
  && echo "JAVA_OPTS=\"\$JAVA_OPTS \$JAVA_MEM_OPTS \$JAVA_DEBUG_OPTS -Djava.security.egd=file:/dev/urandom -Djava.net.preferIPv4Stack=true -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/tomcat${TOMCAT_VERSION} -Dgroovy.use.classvalue=true -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true -Dgrails.env=\$GRAILS_ENV \$PODNAME_OPT -Dcatalina.logdir=\$CATALINA_LOGDIR -Dcas.standalone.configurationDirectory=/var/lib/tomcat${TOMCAT_VERSION}/cas -Dcas.standalone.configurationFile=/var/lib/tomcat${TOMCAT_VERSION}/cas/cas_config.yml -Dactivemq.conf=/var/lib/tomcat${TOMCAT_VERSION}/amq/conf -Dderby.system.home=/var/lib/tomcat${TOMCAT_VERSION}/amq/data/derby -Dorg.apache.activemq.audit=true -Dcom.sun.management.jmxremote.port=11099 -Dcom.sun.management.jmxremote.password.file=/var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.password -Dcom.sun.management.jmxremote.access.file=/var/lib/tomcat${TOMCAT_VERSION}/tomcat-conf/jmx.access -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote\"") >> /etc/default/tomcat${TOMCAT_VERSION}

RUN sed -i 's#${catalina.base}/logs#${catalina.logdir}#' /etc/tomcat${TOMCAT_VERSION}/logging.properties
RUN sed -i 's#${catalina.base}${file.separator}logs#${catalina.logdir}#' /etc/tomcat${TOMCAT_VERSION}/policy.d/03catalina.policy

# Put the PostgreSQL JDBC jar in Tomcat's lib directory
ARG POSTGRESQL_JDBC_VERSION=42.6.0
COPY postgresql-${POSTGRESQL_JDBC_VERSION}.jar.md5 /tmp/
RUN wget https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_JDBC_VERSION}.jar -O /usr/share/tomcat${TOMCAT_VERSION}/lib/postgresql-${POSTGRESQL_JDBC_VERSION}.jar \
      && test "$(md5sum /usr/share/tomcat${TOMCAT_VERSION}/lib/postgresql-${POSTGRESQL_JDBC_VERSION}.jar|cut -d' ' -f1)" = "$(cat /tmp/postgresql-${POSTGRESQL_JDBC_VERSION}.jar.md5|cut -d' ' -f1)"

# Add the CA public key used to issue certs.
COPY tmp_tomcat/bidms_ca_pubkey.pem /usr/local/share/ca-certificates/bidms-ca.crt
# Add the PostgreSQL public key to the system wide trust store
COPY tmp_tomcat/postgres_pubkey.pem /usr/local/share/ca-certificates/bidms-postgresql.crt
# Add the Active Directory CA public key (or, the AD public key)
COPY tmp_tomcat/ad_pubkey.pem /usr/local/share/ca-certificates/bidms-ad.crt
RUN update-ca-certificates

# CAS, if later deployed, may want to write its logs at this location
RUN mkdir -p /var/lib/tomcat${TOMCAT_VERSION}/cas/logs \
  && chown tomcat:tomcat /var/lib/tomcat${TOMCAT_VERSION}/cas/logs \
  && ln -fs /var/lib/tomcat${TOMCAT_VERSION}/cas/logs /var/log/cas

# A ~/.grails/registry-pre.groovy file is necessary to establish a
# configuration directory for BIDMS applications that are later deployed.
# The tomcat user's home directory is /var/lib/tomcat${TOMCAT_VERSION}.
RUN mkdir -p /var/lib/tomcat${TOMCAT_VERSION}/.grails \
  && chown tomcat:tomcat /var/lib/tomcat${TOMCAT_VERSION}/.grails \
  && chmod 700 /var/lib/tomcat${TOMCAT_VERSION}/.grails

COPY registry-pre.groovy  /var/lib/tomcat${TOMCAT_VERSION}/.grails
RUN chown tomcat:tomcat /var/lib/tomcat${TOMCAT_VERSION}/.grails/registry-pre.groovy

RUN rm -rf /core /tmp/*

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
# ActiveMQ Openwire SSL (the JMS messaging port)
EXPOSE 61617
# Optional Java debug port (If debug port enabled, make sure this is
# firewalled!!)
EXPOSE 4782

COPY etc/container/ /etc/container/
ENTRYPOINT ["/etc/container/tomcat-entrypoint.sh", "interactive"]

# Use 'docker inspect <name>' to find the volume files on the host.
# <name> is the value of the --name parameter when invoking docker run.
VOLUME /var/lib/tomcat${TOMCAT_VERSION}
