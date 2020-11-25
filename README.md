# How to setup a web server

This manual provide information about how to setup a CentOS server to work as web server.


| Category      	| Specified     |
| ---------------------	| ------------- |
| OS 			| CentOS 7      |
| DB 			| PostgreSQL 11 |
| Web server 		| nginx 1.x     |
| Serverlet container 	| Tomcat 9.x  	|		
| Backend 		| Java  	|
| Frontend 		| Vue.js  	|
| Authorization Server  | Auth0 	|


Authorization Server
### Prepare server to work 

On local Window:
* connect to server via ssh: `ssh username@ip-address`
* use `WinScp` to transfer files if needed

On server (CentOS7):
* install CentOS 7 On VMware Workstation and set it up with basic configurations.
[How to Install CentOS 7 On VMware Workstation 12](https://darrenoneill.eu/?p=406)
* set server's ip address as `192.168.204.45` and then confirm the connection between server and local machine (here is window). 
* install `netstat` command
```shell
sudo yum -y install net-tools wget curl-devel
```
* disable `SELinux`
```shell
sudo setenforce 0
sudo vi /etc/selinux/config
>> SELINUX = disabled
```

### Install Database

I personally use `postgresql` for my pet project.

```shell
# install posgresql
cd /opt
sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum -y install postgresql11
sudo yum -y install postgresql11-server

# setup postgresql
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
sudo systemctl enable postgresql-11
sudo systemctl start postgresql-11
sudo vi /var/lib/pgsql/11/data/postgresql.conf
>> listen_addresses = '*'
>> port = 5432

sudo vi /var/lib/pgsql/11/data/pg_hba.conf
>> # "local" is for Unix domain socket connections only			
>> local   all             all                                     trust			
>> # IPv4 local connections:			
>> host    all             all             127.0.0.1/32            trust			
>> host    all             all             192.168.204.0/24        trust			
>> # IPv6 local connections:			
>> host    all             all             ::1/128                 trust			
>> # Allow replication connections from localhost, by a user with the			
>> # replication privilege.			
>> #local   replication     all                                     peer			
>> #host    replication     all             127.0.0.1/32            ident			
>> #host    replication     all             ::1/128                 ident			

# start postgresql
sudo systemctl start postgresql-11

# initialize posgresql
sudo -u postgres -i 
$createuser --interactive --pwprompt
Enter name of role to add: myuser
Enter password for new role: ********
Enter it again: ********
Shall the new role be a superuser? (y/n) y
$exit
```

On local machine, install [pgadmin4](https://www.pgadmin.org/download/pgadmin-4-windows/) to access DB
* Create a new DB and name it as `manager`
* Execute `.sql` files for creating tables and adding the initialization data
* In case, DB already exists and dump file is already created, please import `.dump` file to restore DB

### Install JDK 11

```shell
cd /opt
sudo wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.7%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.7_10.tar.gz
sudo tar -xzvf OpenJDK11U-jdk_x64_linux_hotspot_11.0.7_10.tar.gz
sudo chmod -R 757 jdk-11.0.7+10
sudo ln -s jdk-11.0.7+10 JAVA_HOME
sudo alternatives --config java
>>   1           java-1.7.0-openjdk.x86_64 (/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.221-2.6.18.1.el7.x86_64/jre/bin/java)										
>>*+ 2         java-1.8.0-openjdk.x86_64 (/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b03-1.el7.x86_64/jre/bin/java)
>> (Ctrl + C)
sudo alternatives --install /usr/bin/java java /opt/JAVA_HOME/bin/java 2000	
sudo alternatives --config java	
>>   1           java-1.7.0-openjdk.x86_64 (/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.221-2.6.18.1.el7.x86_64/jre/bin/java)			
>>*+ 2         java-1.8.0-openjdk.x86_64 (/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b03-1.el7.x86_64/jre/bin/java)			
>>   3           /opt/JAVA_HOME/bin/java			
>> (3)
sudo alternatives --config java
>>   1           java-1.7.0-openjdk.x86_64 (/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.221-2.6.18.1.el7.x86_64/jre/bin/java)			
>>*  2          java-1.8.0-openjdk.x86_64 (/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b03-1.el7.x86_64/jre/bin/java)			
>> + 3          /opt/JAVA_HOME/bin/java			
>> (Ctrl + C)
```

### Install Maven 3

```shell
cd /opt				
sudo wget http://mirrors.viethosting.com/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz				
sudo tar -xzvf apache-maven-3.6.3-bin.tar.gz				
sudo ln -s apache-maven-3.6.3 MAVEN_HOME				
```

### Install NodeJs 12

```shell
cd /opt			
sudo wget https://nodejs.org/dist/v12.16.2/node-v12.16.2-linux-x64.tar.xz			
sudo tar -xvf node-v12.16.2-linux-x64.tar.xz			
sudo ln -s node-v12.16.2-linux-x64 NODE_HOME			
sudo chmod -R 757 node-v12.16.2-linux-x64			
```

### Install Apache Tomcat 9

```shell
# install apache tomcat
cd /opt
sudo wget http://mirrors.viethosting.com/apache/tomcat/tomcat-9/v9.0.38/bin/apache-tomcat-9.0.38.tar.gz		
sudo tar -xzvf apache-tomcat-9.0.38.tar.gz		
sudo chmod -R 757 apache-tomcat-9.0.38		
sudo ln -s apache-tomcat-9.0.38 TOMCAT_HOME		

# for testing 
cd /opt/TOMCAT_HOME/bin
./startup.sh --- for starting tomcat up
>> go to localhost:8080, the installation is success if tomcat web page is displayed.
./shutdown.sh

# create tomcat service
sudo touch /etc/systemd/system/tomcat.service
# add the following contents in `tomcat.service` file
sudo nano /etc/systemd/system/tomcat.service
>>[Unit]   
>>Description=Tomcat 9 servlet container   
>>After=network.target   
>>   
>>[Service]   
>>Type=forking   
>>   
>>User=tomcat   
>>Group=tomcat   
>>SuccessExitStatus=143
>>   
>>Environment="JAVA_HOME=/opt/JAVA_HOME"   
>>Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"   
>>   
>>Environment="CATALINA_BASE=/opt/TOMCAT_HOME/"   
>>Environment="CATALINA_BASE=/opt/TOMCAT_HOME/"   
>>Environment="CATALINA_PID=/opt/TOMCAT_HOME/temp/tomcat.pid"   
>>Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"   
>>   
>>ExecStart=/opt/TOMCAT_HOME/bin/startup.sh   
>>ExecStop=/opt/TOMCAT_HOME/bin/shutdown.sh   
>>   
>>[Install]   
>>WantedBy=multi-user.target   

# create tomcat user and group
sudo group tomcat 
sudo useradd -m -U -d /opt/TOMCAT_HOME/ -s /bin/false tomcat

# provide a proper permission for tomcat folders
sudo chmod -R 755 /opt/TOMCAT_HOME/bin/
sudo chown -R tomcat:tomcat /opt/TOMCAT_HOME/
sudo sh -c 'chmod +x /opt/TOMCAT_HOME/bin/*.sh'

# enable and start tomcat.service
sudo systemctl enable tomcat
sudo systemctl start tomcat または、sudo systemctl restart tomcat
sudo systemctl status tomcat

# if tomcat.service file is changed, run the ff commands:
sudo systemctl disable tomcat 
sudo systemctl daemon-reload
sudo systemctl restart tomcat
```

To confirm the installation, try to access:
* local: localhost:8080
* network: 192.168.204.45:8080

Using Tomcat web browser
```shell
# create Tomcat user
cd /opt/apache-tomcat-9.0.34/conf	
vi tomcat-users.xml	
>><tomcat-users xmlns="http://tomcat.apache.org/xml"	
>>              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"	
>>              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"	
>>              version="1.0">	
>><user username="admin" password="admin" roles="manager-gui,manager-script"/>	
>></tomcat-users>	
```
Access `'http://192.168.204.45:8080/manager/html` using `admin/admin` account

**Notes**: If *403 Access Denied* error occurs when accessing `/manager/html`

open `/opt/TOMCAT_HOME/webapps/manager/META-INF/context.xml` and comment out `<Value>` tag's content
```shell
<Context antiResourceLocking="false" privileged="true" >
<!--
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->
```

### Configure PATH

```shell
# go to `bashrc` file and add the ff contents: 
vi ~/.bashrc		
>>export JAVA_HOME=/opt/JAVA_HOME		
>>export MAVEN_HOME=/opt/MAVEN_HOME		
>>export NODE_HOME=/opt/NODE_HOME		
>>export PATH=$PATH:$JAVA_HOME/bin:$MAVEN_HOME/bin:$NODE_HOME/bin		

source ~/.bashrc

# confirm the settings
java -version
mvn -v
node -v
```

### Host information

```shell
sudo vi /etc/hosts		
>>127.0.0.1   eqsurv_dbserver		
>>127.0.0.1  eqsurv_webserver		
>>127.0.0.1   eqsurv_tomcatserver		
```

### Install Nginx

```shell
sudo vi /etc/yum.repos.d/nginx.repo	
>>[nginx]	
>>name=nginx repo	
>>baseurl=http://nginx.org/packages/mainline/centos/7/$basearch/	
>>gpgcheck=0	
>>enabled=1	

sudo yum -y install nginx

sudo vi /etc/nginx/nginx.conf		
>>http {		
>>    include       /etc/nginx/mime.types;		
>>    default_type  application/octet-stream;		
>>    upstream eqsurvtomcatserver {		
>>           server 192.168.204.45:8080;		
>>    }		
>>    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '		
>>                      '$status $body_bytes_sent "$http_referer" '		
>>                      '"$http_user_agent" "$http_x_forwarded_for"';		
>>		
>>    access_log  /var/log/nginx/access.log  main;		
>>		
>>    sendfile            on;		
>>    sendfile_max_chunk  5m;		
>>    tcp_nopush          on;		
>>    tcp_nodelay         on;		
>>    types_hash_max_size 2048;		
>>    client_max_body_size 5M;		
>>		
>>    keepalive_timeout  65;		
>>		
>>    #gzip  on;		
>>		
>>    include /etc/nginx/conf.d/*.conf;		
>>}		
		
sudo vi /etc/nginx/conf.d/default.conf		
>>server {		
>>    listen       80 default_server;		
>>    server_name  _;		
>>    root         /usr/share/nginx/html;		
>>		
>>    location /eqsurv/manager/api {		
>>        proxy_set_header X-Forwarded-Host $host;		
>>        proxy_set_header X-Forwarded-Server $host;		
>>        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;		
>>        proxy_pass http://eqsurvtomcatserver/eqsurv-manager;		
>>        proxy_redirect off;		
>>    }		
>>    		
>>    location /eqsurv/manager {		
>>        try_files $uri $uri/ /eqsurv/manager/;		
>>    }		
>>		
>>    error_page   500 502 503 504  /50x.html;		
>>    location = /50x.html {		
>>        root   /usr/share/nginx/html;		
>>    }		
>>}		

# start nginx
sudo systemctl restart nginx

```
 ### Locate resources
 
* create `opt/manager-api` as back-end resources
* create `opt/manager-front` as front-end resources 
* give a proper permission for both folders 
```shell
sudo chmod -R 757 /opt/manager-api
sudo chmod -R 757 /opt/manager-front
```

* create a temporary folder for logging 
```shell
sudo mkdir -p /opt/eqsurv/manager
sudo chmod -R 757 /opt/eqsurv/manager
```

* open `/opt/manager-api/src/main/resources/application.properties` and `/opt/manager-api/src/main/resources/application-production.properties` and update the necessary configurations

### Deploy resources
 To deploy resources, run `build.sh` file
 
