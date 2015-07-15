#Apache Zeppelin on centos 6.6 OS
#(sudo) docker build -t ryba/zeppelin-build .

FROM centos:6.6

MAINTAINER Lucas Bakalian <https://github.com/lucasbak>

WORKDIR /tmp/

##------------------------##
#  BUILDING TOOLS INSTALL  #
##------------------------##

RUN yum clean all
RUN yum update -y
RUN yum install -y wget unzip openssl git rpm tar
RUN yum install -y epel-release
RUN yum groupinstall -y 'Developement Tools'
RUN yum install -y npm

##--------------##
#  JAVA INSTALL  #
##--------------##

#RUN mkdir -p /tmp/jdk
#RUN yum install -y tar
RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm
RUN rpm -ivh jdk-7u79-linux-x64.rpm
ENV JAVA_HOME /usr/java/default

#Test
RUN java -version

##---------------##
#  MAVEN INSTALL  #
##---------------##

RUN wget http://apache.websitebeheerjd.nl/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.zip
RUN unzip apache-maven-3.3.3-bin.zip
RUN mv apache-maven-3.3.3/ /opt/maven
#ADD resources/maven.sh /etc/profile.d/
#ENV MAVEN_HOME=/opt/maven
#ENV PATH=$MAVEN_HOME/bin:$PATH
ENV MAVEN_HOME /opt/maven
ENV PATH $MAVEN_HOME/bin:$PATH
RUN export PATH MAVEN_HOME
RUN export CLASSPATH=.
  
#Test
RUN mvn -version

##----------------##
#  ZEPPELIN BUILD  #
##----------------##

WORKDIR /tmp/
RUN git clone https://github.com/apache/incubator-zeppelin.git
RUN wget https://nodejs.org/dist/v0.10.36/node-v0.10.36-linux-x64.tar.gz 
RUN ls -l /tmp/
RUN tar -C /usr/local --strip-components 1 -xzf /tmp/node-v0.10.36-linux-x64.tar.gz
WORKDIR /tmp/incubator-zeppelin/zeppelin-web
RUN ls -l
RUN npm cache clean
RUN npm  --registry http://registry.npmjs.eu/ install -g bower
RUN npm  --registry http://registry.npmjs.eu/ install  bower
RUN bower -v
RUN yum install -y bzip2
RUN npm --registry http://registry.npmjs.eu/ install  grunt-cli
RUN npm --registry http://registry.npmjs.eu/  install
RUN ls -l node_modules
RUN echo Y | bower --allow-root install
RUN ls -l node_modules
#RUN mvn clean package -e -X -U -Pspark-1.2 -Dspark.version=1.2.1 -Dhadoop.version=2.6.0 -Phadoop-2.4 -Pyarn -DskipTests
WORKDIR /tmp/incubator-zeppelin/
RUN mvn clean package -e -X  -Pspark-1.2 -Dspark.version=1.2.1 -Dhadoop.version=2.6.0 -Phadoop-2.4 -Pyarn -DskipTests
WORKDIR /tmp/
RUN mv /tmp/incubator-zeppelin /tmp/zeppelin-build
RUN tar -chzf zeppelin-build.tar.gz zeppelin-build
RUN mv zeppelin-build.tar.gz /