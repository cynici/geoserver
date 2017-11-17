FROM frolvlad/alpine-oraclejdk8:latest
LABEL maintainer "Cheewai Lai <clai@csir.co.za>"

ARG TOMCAT_VERSION=8.5.23
ARG SUEXEC_VERSION=0.2
ARG DOCKERIZE_VERSION=0.5.0

ARG GEOSERVER_VERSION=2.12
ARG GEOSERVER_PLUGINS="cas feature-pregeneralized imagemosaic-jdbc monitor mysql pyramid wps"
ARG GEOSERVER_CPLUGINS="geofence"
ARG GEOSERVER_BASE_URL="http://ares.boundlessgeo.com/geoserver/${GEOSERVER_VERSION}.x"

ENV JAVA_HOME=/usr/lib/jvm/default-jvm
# SET CATALINE_HOME and PATH
ENV CATALINA_HOME /usr/tomcat

# Tunable JVM parameters
ENV JMX false
ENV JMX_PORT 9004
ENV JMX_HOSTNAME localhost
ENV DEBUG_PORT 8000
ENV PERM 128m
ENV MAXPERM 256m
ENV MINMEM 128m
ENV MAXMEM 512m
ENV PATH $PATH:/usr/bin:/usr/local/bin:$CATALINA_HOME/bin

RUN buildDeps='curl unzip ca-certificates openssl g++ make' HOME='/root' \
 && set -x \
 && apk add --update $buildDeps \
 && wget -O- https://github.com/ncopa/su-exec/archive/v${SUEXEC_VERSION}.tar.gz | tar zxvf - \
 && cd su-exec-${SUEXEC_VERSION} \
 && make \
 && mv su-exec /usr/bin \
 && cd .. && rm -rf su-exec-${SUEXEC_VERSION} \
 && chmod +x /usr/bin/su-exec \
 && curl -fsSL "https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-alpine-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz" | tar -C /usr/bin -xzvf - \
 && curl --silent --location --retry 3 --cacert /etc/ssl/certs/ca-certificates.crt "https://archive.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
    | gunzip \
    | tar x -C /usr/ \
 && mv /usr/apache-tomcat* /usr/tomcat \
 && mkdir -p /tmp/gs/plugins \
 && cd /tmp/gs \
 && wget "${GEOSERVER_BASE_URL}/geoserver-${GEOSERVER_VERSION}.x-latest-war.zip" -O geoserver.zip \
 && for _p in $GEOSERVER_CPLUGINS ; do wget -c "${GEOSERVER_BASE_URL}/community-latest/geoserver-${GEOSERVER_VERSION}-SNAPSHOT-${_p}-plugin.zip" -O plugins/${_p}.zip; done \
 && for _p in $GEOSERVER_PLUGINS ; do wget -c "${GEOSERVER_BASE_URL}/ext-latest/geoserver-${GEOSERVER_VERSION}-SNAPSHOT-${_p}-plugin.zip" -O plugins/${_p}.zip; done \
 && unzip geoserver.zip geoserver.war \
 && unzip geoserver.war -d $CATALINA_HOME/webapps/geoserver \
 && find plugins -type f -name "*.zip" | xargs -i unzip {} -d $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/ \
 && cd / \
 && rm -rf $CATALINA_HOME/webapps/geoserver/data \
 && rm -rf /tmp/geoserver \
 && apk del --purge $buildDeps

COPY local_policy.jar /usr/lib/jvm/default-jvm/jre/lib/security/
COPY US_export_policy.jar /usr/lib/jvm/default-jvm/jre/lib/security/
ADD setenv.sh $CATALINA_HOME/bin/
ADD docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
