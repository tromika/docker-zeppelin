#!/usr/bin/env bash
cd /incubator-zeppelin/
mvn clean package -Pspark-1.5 -Dspark.version=1.5.2 -Dhadoop.version=2.7.0 -Phadoop-2.6 -Pyarn -DskipTests
