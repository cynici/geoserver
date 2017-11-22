# Geoserver in Docker with Tomcat and Oracle JRE

Use this repo to build a small footprint docker image containing the following based on [alpine linux](https://hub.docker.com/_/alpine/):

- Tomcat (versions tested compatible with Geoserver)
- Oracle JDK 8
- su-exec
- dockerize

To enable strong cryptography in Oracle JRE, the image contains *local_policy.jar* and *US_export_policy.jar* extracted from http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip

The Dockerfile is adapted from the following primarily because Oracle JDK 7 is [no longer available](http://www.oracle.com/technetwork/java/javase/overview/index.html)

- https://hub.docker.com/r/sdd330/alpine-oraclejdk7/~/dockerfile/
- https://hub.docker.com/r/sdd330/alpine-tomcat-oraclejdk/

[su-exec](https://github.com/ncopa/su-exec) has been included so that tomcat would run as non-root user for better security. The docker image uses `/docker-entrypoint.sh` to run tomcat as non-root user. The numeric UID of this user in the container defaults to 1000 but it may be overridden with the environment variable *TOMCAT_UID*.

[dockerize](https://github.com/jwilder/dockerize) may be used to wait for any dependent container (service) to be ready before starting Tomcat. To use it, define the environment variable *DOCKERIZE_CMD* with the full command, e.g. `dockerize -wait=tcp://my_postgresql_host_ip:5432 -timeout=30m`.

Even though GeoServer has only been officially tested with JRE7, it seems to [work fine with JRE8](http://osdir.com/ml/geoserver-development-geospatial-java/2015-01/msg00331.html).

## Usage

Tomcat webapps directory in the container is */usr/tomcat/webapps/*

Override any JRE JAVA [default values](https://github.com/cynici/tomcat/blob/master/Dockerfile) using *environment* in docker-compose.yml file. GeoServer requires MINMEM greater or equal to 64 MB.

A complete sample `docker-compose.yml` may look like this:

```
geoserver:
  image: cheewai/tomcat
  environment:
    - TOMCAT_UID=1001
    - MAXMEM=2048m
    - GEOSERVER_DATA_DIR=/var/geoserver
    - GEOSERVER_LOG_LOCATION=/logs/geoserver.log
  volumes:
    - ./gsdata:/var/geoserver
    - ./logs:/logs
  ports:
    - "8080:8080"
```

### Recommended Resource Limits

When Geoserver starts up, its CPU and RAM usage spikes. If you don't provide enough, it will take a long time to be ready, if at all.

Using docker-compose.yml version 3 for `docker stack deploy`:

```
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 3g
```

Using docker-compose.yml version 2.2 for `docker-compose`:

``` 
    cpus: 4
    mem_limit: 3g
```


## CAVEAT

* If you include community plugin `geofence` and leave it unconfigured, Geoserver will malfunction

