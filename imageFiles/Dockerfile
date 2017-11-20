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
       libservlet3.1-java telnet dnsutils \
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

# Copy the keystore for TLS
RUN mkdir /etc/tomcat${TOMCAT_VERSION}/certs
COPY tmp_tomcat/tomcat.jks /etc/tomcat${TOMCAT_VERSION}/certs
COPY tmp_tomcat/tomcat_pubkey.pem /etc/tomcat${TOMCAT_VERSION}/certs
RUN chmod 640 /etc/tomcat${TOMCAT_VERSION}/certs/tomcat.jks \
  && chgrp tomcat${TOMCAT_VERSION} \
       /etc/tomcat${TOMCAT_VERSION}/certs/tomcat.jks \
       /etc/tomcat${TOMCAT_VERSION}/certs/tomcat_pubkey.pem

# Only user and group readable because of the JNDI secrets in server.xml.
# This fine is installed as root and tomcat is the group, so it has to be
# group readable.
RUN chmod 640 /etc/tomcat${TOMCAT_VERSION}/server.xml

RUN sed -i 's#directory="logs"#directory="${catalina.logdir}"#' /etc/tomcat${TOMCAT_VERSION}/server.xml

# Add the JNDI resource for the BIDMS database connection pool
RUN sed -f /tmp/tmp_tomcat/globalnaming_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/server.xml

# Add the different TLS port numbers, each pointing to a different webapps
# base directory.  This gives more flexibility to protect applications
# running on different ports differently, such as with a firewall.
RUN mkdir -p /usr/local/tomcat/webapps \
  && mkdir \
       /usr/local/tomcat/webapps/bidms-user-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsUserFrontend \
       /usr/local/tomcat/webapps/bidms-admin-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAdminFrontend \
       /usr/local/tomcat/webapps/bidms-restapi-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsRestapiFrontend \
       /usr/local/tomcat/webapps/bidms-backend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsBackend \
       /usr/local/tomcat/webapps/amq \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAMQ \
  && chown tomcat${TOMCAT_VERSION}:tomcat${TOMCAT_VERSION} \
       /usr/local/tomcat/webapps/bidms-user-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsUserFrontend \
       /usr/local/tomcat/webapps/bidms-admin-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAdminFrontend \
       /usr/local/tomcat/webapps/bidms-restapi-frontend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsRestapiFrontend \
       /usr/local/tomcat/webapps/bidms-backend \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsBackend \
       /usr/local/tomcat/webapps/amq \
       /etc/tomcat${TOMCAT_VERSION}/CatalinaBidmsAMQ \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /usr/local/tomcat/webapps/bidms-user-frontend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /usr/local/tomcat/webapps/bidms-admin-frontend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /usr/local/tomcat/webapps/bidms-restapi-frontend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /usr/local/tomcat/webapps/bidms-backend/manager \
  && ln -fs /usr/share/tomcat${TOMCAT_VERSION}-admin/manager \
       /usr/local/tomcat/webapps/amq/manager \
  && sed -f /tmp/tmp_tomcat/server_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/server.xml \
  && sed -f /tmp/tmp_tomcat/context_objects.sed -i /etc/tomcat${TOMCAT_VERSION}/context.xml

RUN (echo "\nGRAILS_ENV=development" \
  && echo "PODNAME=\$(if [ -f /podinfo/name ]; then cat /podinfo/name; fi)" \
  && echo "CATALINA_LOGDIR=\$(if [ -z \"\$PODNAME\" ]; then echo \"logs\"; else echo \"logs/\$PODNAME\"; fi)" \
  && echo "if [ ! -z \"\$PODNAME\" ]; then\n  if [ ! -d \"/var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}\" ]; then\n    mkdir /var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}\n    chown tomcat${TOMCAT_VERSION}:tomcat${TOMCAT_VERSION} /var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}\n  fi\n  CATALINA_OUT=\"/var/lib/tomcat${TOMCAT_VERSION}/logs/\${PODNAME}/catalina.out\"\nfi" \
  && echo "PODNAME_OPT=\$(if [ ! -z \"\$PODNAME\" ]; then echo \"-Dcatalina.podname=\$PODNAME\"; fi)" \
  && echo "JAVA_OPTS=\"\$JAVA_OPTS -Djava.net.preferIPv4Stack=true -Dgrails.env=\$GRAILS_ENV -Dregistry.config.location=/var/lib/tomcat${TOMCAT_VERSION}/registry \$PODNAME_OPT -Dcatalina.logdir=\$CATALINA_LOGDIR -Dhazelcast.config=/etc/tomcat${TOMCAT_VERSION}/hazelcast.xml\"") >> /etc/default/tomcat${TOMCAT_VERSION}

RUN sed -i 's#${catalina.base}/logs#${catalina.logdir}#' /etc/tomcat${TOMCAT_VERSION}/logging.properties
RUN sed -i 's#${catalina.base}${file.separator}logs#${catalina.logdir}#' /etc/tomcat${TOMCAT_VERSION}/policy.d/03catalina.policy

ARG HAZELCAST_VERSION=3.9
COPY hazelcast-all-${HAZELCAST_VERSION}.jar.md5 /tmp/
RUN wget https://jcenter.bintray.com/com/hazelcast/hazelcast-all/${HAZELCAST_VERSION}/hazelcast-all-${HAZELCAST_VERSION}.jar -O /usr/share/tomcat${TOMCAT_VERSION}/lib/hazelcast-all-${HAZELCAST_VERSION}.jar \
  && test "$(md5sum /usr/share/tomcat${TOMCAT_VERSION}/lib/hazelcast-all-${HAZELCAST_VERSION}.jar|cut -d' ' -f1)" = "$(cat /tmp/hazelcast-all-${HAZELCAST_VERSION}.jar.md5|cut -d' ' -f1)"

ARG HAZELCAST_TOMCAT_SESSION_MGR_VERSION=1.1.2
COPY hazelcast-tomcat85-sessionmanager-${HAZELCAST_TOMCAT_SESSION_MGR_VERSION}.jar.md5 /tmp/
RUN wget https://github.com/hazelcast/hazelcast-tomcat-sessionmanager/releases/download/v${HAZELCAST_TOMCAT_SESSION_MGR_VERSION}/hazelcast-tomcat85-sessionmanager-${HAZELCAST_TOMCAT_SESSION_MGR_VERSION}.jar -O /usr/share/tomcat${TOMCAT_VERSION}/lib/hazelcast-tomcat85-sessionmanager-${HAZELCAST_TOMCAT_SESSION_MGR_VERSION}.jar \
  && test "$(md5sum /usr/share/tomcat${TOMCAT_VERSION}/lib/hazelcast-tomcat85-sessionmanager-${HAZELCAST_TOMCAT_SESSION_MGR_VERSION}.jar|cut -d' ' -f1)" = "$(cat /tmp/hazelcast-tomcat85-sessionmanager-${HAZELCAST_TOMCAT_SESSION_MGR_VERSION}.jar.md5|cut -d' ' -f1)"

COPY hazelcast.xml /tmp

# replace the passwords/salts in hazelcast.xml with the ones from files in
# tmp_passwords
RUN /tmp/tmp_passwords/replaceString.pl /tmp/tmp_passwords/hazelcast_group_pw /tmp/hazelcast.xml GROUP_PASSWORD | \
      /tmp/tmp_passwords/replaceString.pl /tmp/tmp_passwords/hazelcast_enc_pw - ENC_PW | \
      /tmp/tmp_passwords/replaceString.pl /tmp/tmp_passwords/hazelcast_salt_pw - ENC_SALT \
        > /etc/tomcat${TOMCAT_VERSION}/hazelcast.xml \
  && chgrp tomcat${TOMCAT_VERSION} /etc/tomcat${TOMCAT_VERSION}/hazelcast.xml \
  && chmod 640 /etc/tomcat${TOMCAT_VERSION}/hazelcast.xml

# https://github.com/hazelcast/hazelcast-kubernetes
# Kubernetes discovery is disabled by default.  Change in config.env.
ARG HAZELCAST_KUBERNETES_ENABLE=
ARG HAZELCAST_KUBERNETES_VERSION=1.0.0
ARG DNSJAVA_VERSION=2.1.8
COPY hazelcast-kubernetes-${HAZELCAST_KUBERNETES_VERSION}.jar.md5 /tmp/
COPY dnsjava-${DNSJAVA_VERSION}.jar.md5 /tmp/
RUN if [ ! -z "$HAZELCAST_KUBERNETES_ENABLE" ]; then ( \
  wget https://github.com/hazelcast/hazelcast-kubernetes/releases/download/v${HAZELCAST_KUBERNETES_VERSION}/hazelcast-kubernetes-${HAZELCAST_KUBERNETES_VERSION}.jar -O /usr/share/tomcat${TOMCAT_VERSION}/lib/hazelcast-kubernetes-${HAZELCAST_KUBERNETES_VERSION}.jar \
    && test "$(md5sum /usr/share/tomcat${TOMCAT_VERSION}/lib/hazelcast-kubernetes-${HAZELCAST_KUBERNETES_VERSION}.jar|cut -d' ' -f1)" = "$(cat /tmp/hazelcast-kubernetes-${HAZELCAST_KUBERNETES_VERSION}.jar.md5|cut -d' ' -f1)" \
    && wget https://jcenter.bintray.com/dnsjava/dnsjava/${DNSJAVA_VERSION}/dnsjava-${DNSJAVA_VERSION}.jar -O /usr/share/tomcat${TOMCAT_VERSION}/lib/dnsjava-${DNSJAVA_VERSION}.jar \
    && test "$(md5sum /usr/share/tomcat${TOMCAT_VERSION}/lib/dnsjava-${DNSJAVA_VERSION}.jar|cut -d' ' -f1)" = "$(cat /tmp/dnsjava-${DNSJAVA_VERSION}.jar.md5|cut -d' ' -f1)"); \
fi

# Add discovery configuration to hazelcast.xml.
RUN if [ -z "$HAZELCAST_KUBERNETES_ENABLE" ]; then sed -f /tmp/tmp_tomcat/hazelcast_join_discovery_memberlist.sed -i /etc/tomcat${TOMCAT_VERSION}/hazelcast.xml; else sed -f /tmp/tmp_tomcat/hazelcast_join_discovery_kubernetes.sed -i /etc/tomcat${TOMCAT_VERSION}/hazelcast.xml; fi

# Replace membership list, if the membership file exists, otherwise leave
# list at default.
RUN if [ -z "$HAZELCAST_KUBERNETES_ENABLE" -a -f /tmp/tmp_tomcat/hazelcast_members.xml ]; then sed -f /tmp/tmp_tomcat/hazelcast_members.sed -i /etc/tomcat${TOMCAT_VERSION}/hazelcast.xml; fi

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

COPY etc/container/ /etc/container/
ENTRYPOINT ["/etc/container/tomcat-entrypoint.sh", "interactive"]

# Use 'docker inspect <name>' to find the volume files on the host.
# <name> is the value of the --name parameter when invoking docker run.
VOLUME /var/lib/tomcat${TOMCAT_VERSION}
