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


RUN apt-get -y install curl python-dev

RUN curl -sSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

RUN apt-get -y install git
RUN apt-get -y install npm
RUN apt-get -y install libfontconfig
RUN git clone https://github.com/apache/incubator-zeppelin.git



RUN cd incubator-zeppelin  && git pull https://github.com/felixcheung/incubator-zeppelin spark16




ADD warm_maven.sh /usr/local/bin/warm_maven.sh
ADD scripts/start-script.sh /start-script.sh
ADD scripts/configured_env.sh /configured_env.sh
RUN /usr/local/bin/warm_maven.sh


# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH


#Python install
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    echo "6c6b44acdd0bc4229377ee10d52c8ac6160c336d9cdd669db7371aa9344e1ac3 *Miniconda3-3.9.1-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash Miniconda3-3.9.1-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.14.1


    # Install Python 2 packages
RUN conda create -p $CONDA_DIR/envs/python2 python=2.7 \
        'pandas=0.17*' \
        'matplotlib=1.4*' \
        'scipy=0.16*' \
        'seaborn=0.6*' \
        'bokeh=0.10*' \
        'scikit-learn=0.16*' \
        pyzmq \
        && conda clean -yt



WORKDIR /tmp
RUN \
  apt-get install -y curl  docker.io && \
  curl -s -O https://downloads.mesosphere.io/master/ubuntu/14.04/mesos_${VERSION}-${PKG_RELEASE}.ubuntu1404_amd64.deb && \
  dpkg --unpack mesos_${VERSION}-${PKG_RELEASE}.ubuntu1404_amd64.deb && \
  apt-get install -f -y && \
  rm mesos_${VERSION}-${PKG_RELEASE}.ubuntu1404_amd64.deb && \
  apt-get clean

RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.6.0-bin-hadoop2.6.tgz  | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s spark-1.6.0-bin-hadoop2.6 spark


ENV SPARK_HOME /usr/local/spark
ENV MESOS_NATIVE_LIBRARY /usr/lib/libmesos.so
ENV PYTHONPATH $SPARK_HOME/python/:$PYTHONPATH
ENV PYTHONPATH $SPARK_HOME/python/lib/py4j-0.9-src.zip:$PYTHONPATH
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle/


EXPOSE 8080 8081
