#!/bin/sh

/usr/bin/perl -p -0 -i -e 's/tomcat\.util\.scan\.StandardJarScanFilter\.jarsToSkip=(.*?)\n\n/tomcat.util.scan.StandardJarScanFilter.jarsToSkip=\\*.jar\n\n/igs' $1
