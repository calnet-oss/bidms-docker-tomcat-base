## Purpose

This [Docker](http://www.docker.com/) image runs a
[Tomcat](http://tomcat.apache.org/) application server and exposes several
https ports that serve different groups of applications.  There's multiple
ports for different web applications to allow for flexibility with firewall
rules.

The author does not currently publish the image in any public Docker
repository but a script, described below, is provided to easily create your
own image.

## License

The source code, which in this project is primarily shell scripts and the
Dockerfile, is licensed under the [BSD two-clause license](LICENSE.txt).

## Building the Docker image

Copy `config.env.template` to `config.env` and edit to set config values.

Create the `imageFiles/tmp_passwords/tomcat_manager_pw` file and set a
Tomcat manager password, which allows you to authenticate into the Tomcat
manager web UI application.  Also create the
`imageFiles/tmp_passwords/tomcat_manager-script_pw` file and set a Tomcat
manager-script password, which allows you to authenticate into the Tomcat
manager web endpoint for deploying and undeploying applications via build
tools like Gradle or by using a continuous integration system to deploy.

Make sure they are only readable by the owner:
```
chmod 600 imageFiles/tmp_passwords/tomcat_manager_pw \
  imageFiles/tmp_passwords/tomcat_manager-script_pw
```

Copy or the public key for PostgGreSQL to
`imageFiles/tmp_tomcat/postgres_pubkey.pem`.  Assuming you're using
[bidms-docker-postgresql](http://github.com/calnet-oss/bidms-docker-postgresql)
and you have it checked out in a directory above this one:
```
(cd imageFiles/tmp_tomcat && cp ../../../bidms-docker-postgresql/imageFiles/tls/pubkey.pem postgres_pubkey.pem)
```

Generate the key pair that Tomcat will use for TLS:
```
./generateTLSCert.sh
```

Two files are generated:
* `imageFiles/tmp_tomcat/tomcat.jks` - The Java keystore used by Tomcat.
* `imageFiles/tmp_tomcat/tomcat_pubkey.pem` - Tomcat's TLS public key.

This image depends on the the base BIDMS Debian Docker image from the
[bidms-docker-debian-base](http://www.github.com/calnet-oss/bidms-docker-debian-base)
project.  If you don't have that image built yet, you'll need that first.

Make sure the `HOST_TOMCAT_DIRECTORY` directory specified in `config.env`
does not exist yet on your host machine (unless you're running
`buildImage.sh` subsequent times and want to keep your existing run files)
so that the build script will initialize your application server.

Build the container image:
```
./buildImage.sh
```

## Installing the Docker network bridge

This container requires the `bidms_nw` [user-defined Docker network
bridge](https://docs.docker.com/engine/userguide/networking/#bridge-networks)
before running.  If you have not yet created this network bridge on your
host (only needs to be done once), do so by running:
```
./createNetworkBridge.sh
```

If you don't remember if you have created this bridge yet, you can check by
issuing the following command (you should see `bidms_nw` listed as one of
the named networks):
```
docker network ls
```

## Running

To run the container interactively (which means you get a shell prompt):
```
./runContainer.sh
```

Or to run the container detached, in the background:
```
./detachedRunContainer.sh
```

If everything goes smoothly, the container should expose several https
ports.

If running interactively, you can exit the container by exiting the bash
shell.  If running in detached mode, you can stop the container with:
`docker stop bidms-tomcat` or there is a `stopContainer.sh` script included
to do this.

To inspect the running container from the host:
```
docker inspect bidms-tomcat
```

To list the running containers on the host:
```
docker ps
```

## Tomcat Ports

The container exposes several https ports.  These ports are redirected to
ports on the host, where the host port numbers are specified in
`config.env`.  

In this context, "front-end" means an user-facing application or an
application that exposes externally available REST endpoints.  "Externally
available" means available to users or computers outside the BIDMS stack of
services.  It does not mean available to everyone.  "Back-end" means an
application that isn't user-facing or externally available: i.e., it's
internal to the BIDMS stack and does not need to be accessed by anything
other than BIDMS software.
  * LOCAL_BIDMS_USER_FRONTEND_TOMCAT_PORT (default: 8340)
    * BIDMS user-facing front-end web applications.
  * LOCAL_BIDMS_ADMIN_FRONTEND_TOMCAT_PORT (default: 8341)
    * BIDMS administrator-facing front-end web applications.
    * Should be protected, at least, by firewall rules that limit access to
      your organization's network, assuming your administrators belong to
      your organization.
  * LOCAL_BIDMS_RESTAPI_FRONTEND_TOMCAT_PORT (default: 8342)
    * BIDMS externally available REST APIs.
    * This doesn't mean all the services running within these applications
      should be externally accessible.  Rather, it means the application has
      at least one service that should be externally accessible and
      therefore needs looser firewall restrictions in order to expose the
      service.  At a minimum, you should limit access to these services to
      within your organization's network.
  * LOCAL_BIDMS_BACKEND_TOMCAT_PORT (default: 8343)
    * BIDMS back-end web applications.
    * Should be tightly protected by at least one firewall that denies
      access to just about everything except maybe other backend BIDMS
      servers operating within a BIDMS backend cluster.
  * LOCAL_AMQ_TOMCAT_PORT (default: 8344)
    * ActiveMQ web console
    * Should be tightly protected by at least one firewall that denies
      access to just about everything except maybe other backend BIDMS
      servers operating within a BIDMS backend cluster.
  * LOCAL_AMQ_OPENWIRE_SSL_PORT (default: 61617)
    * ActiveMQ Openwire SSL (the JMS messaging port)
    * Should be tightly protected by at least one firewall that denies
      access to just about everything except maybe other backend BIDMS
      servers operating within a BIDMS backend cluster.
  * LOCAL_JVM_DEBUG_PORT (optional, default: 4782)
    * Port for JVM debugger.
    * Should be tightly protected by a firewall.

There are opportunities to split this further if you need further
flexibility with setting even finer-grained firewall rules for the various
applications.  At the finest level, you could have a port number for each
web application.

Although there shouldn't be a reason, if you wish to connect to the Tomcat
manager web UI application, visit
```
https://localhost:PORT/manager/html/
```
Replace PORT with the port number.  There is a manager app running on each
port.

## Tomcat File Persistence

Docker will mount the host directory specified in `HOST_TOMCAT_DIRECTORY`
from `config.env` within the container as `/var/lib/tomcat9` and this is how
the application server run files are persisted across container runs.

As mentioned in the build image step, the `buildImage.sh` script will
initialize the Tomcat run files as long as the `HOST_TOMCAT_DIRECTORY`
directory doesn't exist yet on the host at the time `buildImage.sh` is run. 
Subsequent runs of `buildImage.sh` will not re-initialize these files if
the directory already exists.

If you plan on running the image on hosts separate from the machine you're
running the `buildImage.sh` script on then you'll probably want to let
`buildImage.sh` initialize the run files and then copy the
`HOST_TOMCAT_DIRECTORY` to all the machines that you will be running the
image on.  When copying, be careful about preserving file permissions.
