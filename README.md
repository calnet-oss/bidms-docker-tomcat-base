## Purpose

This [Docker](http://www.docker.com/) image runs a
[Tomcat](http://tomcat.apache.org/) application server and exposes the https
port on 8040.

The author does not currently publish the image in any public Docker
repository but a script, described below, is provided to easily create your
own image.

## License

The source code, which in this project is primarily shell scripts and the
Dockerfile, is licensed under the [BSD two-clause license](LICENSE.txt).

## Building the Docker image

Copy `config.env.template` to `config.env` and edit to set config values.

Create `imageFiles/tmp_passwords/tomcat_manager_pw` file and set a Tomcat
manager password, which allows you to authentication into the Tomcat manager
app.

Make sure it's only readable by the owner:
```
chmod 600 imageFiles/tmp_passwords/tomcat_manager_pw
```

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

## Running

To run the container interactively (which means you get a shell prompt):
```
./runContainer.sh
```

Or to run the container detached, in the background:
```
./detachedRunContainer.sh
```

If everything goes smoothly, the container should expose port 8040, the
Tomcat https port.  This port is redirected to a port on the host, where the
host port number is specified in `config.env` as `LOCAL_TOMCAT_PORT`.

You can then use your favorite web browser to connect to the Tomcat manager
app, which should be running at
(https://localhost:8040/manager/html/)[https://localhost:8040/manager/html/]
if you have `LOCAL_TOMCAT_PORT` configured as port 8040 in `config.env`.

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

## Tomcat File Persistence

Docker will mount the host directory specified in `HOST_TOMCAT_DIRECTORY`
from `config.env` within the container as `/var/lib/tomcat8` and this is how
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
