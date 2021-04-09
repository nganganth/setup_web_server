#!/bin/sh
# This file is used whenever resources are updated/changed
# To build/generate war file using mvn, and then copy to destination folder
cd /opt/manager-front
make build
wait
echo "Front-end is already re-built!"
cd /opt/manager-api
mvn clean package
echo "Api is already created!"
wait
sudo cp /opt/manager-api/target/manager.war /opt/TOMCAT_HOME/webapps/
