#Run Zeppelin 

FROM centos:6.6


##-------------------##
#  JAVA INSTALL       #
##-------------------##

RUN yum install -y wget tar
#RUN mkdir -p /tmp/jdk
#RUN yum install -y tar
RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm
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

##-------------------##
#  Zeppelin CONFIGURE #
##-------------------##

RUN yum install -y epel-release
RUN yum install -y supervisor

RUN rm -rf /etc/supervisord.conf
ADD resources/supervisord.conf /etc/supervisord.conf
ADD resources/zeppelin_notebook.conf /etc/supervisor/conf.d/
RUN service supervisord start
RUN supervisorctl start zeppelin_notebook
RUN service supervisord stop

#ENTRYPOINT ["/var/lib/zeppelin/bin/zeppelin-daemon.sh","--config","/var/lib/zeppelin/conf"]
ENTRYPOINT ["/usr/bin/supervisord","-n"]