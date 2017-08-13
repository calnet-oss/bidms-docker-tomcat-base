#!/bin/sh

if [ -z "$KEYSIZE" ]; then
  KEYSIZE=4096
fi

echo "Generating key.  This can take a few seconds."
keytool -genkey -alias tomcat -keyalg RSA -keysize $KEYSIZE \
       -validity 10000 \
       -storepass "changeit" -keypass "changeit" \
       -dname "CN=bidms-tomcat,OU=BIDMS Tomcat Docker Dev" \
       -keystore imageFiles/tmp_tomcat/tomcat.jks
chmod 600 imageFiles/tmp_tomcat/tomcat.jks

keytool -exportcert -alias tomcat \
  -storepass "changeit"  -keystore imageFiles/tmp_tomcat/tomcat.jks \
  -rfc \
  -file imageFiles/tmp_tomcat/tomcat_pubkey.pem
