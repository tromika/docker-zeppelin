FROM    ubuntu:14.04

MAINTAINER Pakhomov Egor <pahomov.egor@gmail.com>

ENV VERSION 0.25.0
ENV PKG_RELEASE 0.2.70
ENV MAVEN_VERSION 3.3.3

RUN apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes software-properties-common python-software-properties
RUN apt-add-repository -y ppa:webupd8team/java
RUN apt-get -y update
RUN /bin/echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install oracle-java7-installer oracle-java7-set-default


RUN apt-get -y install curl
RUN curl -sSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

RUN apt-get -y install git
RUN apt-get -y install npm
RUN apt-get -y install libfontconfig
RUN git clone https://github.com/apache/incubator-zeppelin.git

ADD warm_maven.sh /usr/local/bin/warm_maven.sh
ADD scripts/start-script.sh /start-script.sh
ADD scripts/configured_env.sh /configured_env.sh
RUN /usr/local/bin/warm_maven.sh


WORKDIR /tmp
RUN \
  apt-get install -y curl openjdk-6-jre-headless docker.io && \
  curl -s -O https://downloads.mesosphere.io/master/ubuntu/14.04/mesos_${VERSION}-${PKG_RELEASE}.ubuntu1404_amd64.deb && \
  dpkg --unpack mesos_${VERSION}-${PKG_RELEASE}.ubuntu1404_amd64.deb && \
  apt-get install -f -y && \
  rm mesos_${VERSION}-${PKG_RELEASE}.ubuntu1404_amd64.deb && \
  apt-get clean

RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.5.1-bin-hadoop2.6.tgz  | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s spark-1.5.1-bin-hadoop2.6 spark


ENV SPARK_HOME /usr/local/spark
ENV MESOS_NATIVE_LIBRARY /usr/lib/libmesos.so
ENV PYTHONPATH $SPARK_HOME/python/:$PYTHONPATH
ENV PYTHONPATH $SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip:$PYTHONPATH



EXPOSE 8080 8081
