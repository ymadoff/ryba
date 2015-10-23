#Run Zeppelin 

FROM centos:6.6


##-------------------##
#  JAVA INSTALL       #
##-------------------##

RUN yum install -y wget tar
#RUN mkdir -p /tmp/jdk
#RUN yum install -y tar
#RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm
RUN curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm"
RUN rpm -ivh jdk-7u79-linux-x64.rpm
ENV JAVA_HOME /usr/java/default

#Test
RUN java -version

##-------------------##
#  Zeppelin INSTALL   #
##-------------------##

ADD resources/zeppelin-build.tar.gz /tmp/
RUN ls -l /tmp/
#RUN mkdir -p /var/lib/zeppelin
#RUN tar -xzf /tmp/zeppelin-build.tar.gz -C /var/lib/zeppelin/ --strip-components=1
RUN mv /tmp/zeppelin-build /var/lib/zeppelin


RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum install -y supervisor krb5-server krb5-libs krb5-auth-dialog krb5-workstation vim
ADD resources/local_policy.jar /usr/java/jdk1.7.0_79/jre/lib/security/
ADD resources/US_export_policy.jar /usr/java/jdk1.7.0_79/jre/lib/security/

RUN useradd spark
RUN groupadd hadoop
RUN usermod -g hadoop spark



ENTRYPOINT ["/var/lib/zeppelin/bin/zeppelin.sh","--config","/var/lib/zeppelin/conf"]