# RUN HUE

FROM centos:6.6

# YUM #

RUN yum install -y wget tar python krb5-server krb5-libs krb5-workstation vim
RUN yum install -y libxslt-devel
RUN yum install -y mysql mysql-connector-java
RUN yum install -y snappy
RUN yum install -y python-devel
RUN yum install -y openssl-devel
RUN yum install -y libxslt-devel
RUN yum install -y cyrus-sasl-gssapi unzip

#  JAVA INSTALL   #

RUN curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm"
RUN rpm -ivh jdk-7u79-linux-x64.rpm
ENV JAVA_HOME /usr/java/default

# Custom Dependencies #

COPY resources/hue-build.tar.gz /var/lib/
WORKDIR /tmp/
RUN curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"
RUN unzip UnlimitedJCEPolicyJDK7.zip
RUN cp UnlimitedJCEPolicy/local_policy.jar /usr/java/jdk1.7.0_79/jre/lib/security/
RUN cp UnlimitedJCEPolicy/US_export_policy.jar /usr/java/jdk1.7.0_79/jre/lib/security/
RUN rm -rf ./UnlimitedJCEPolicyJDK7*

# Hue Layout #

RUN groupadd hue -g 2410
RUN useradd hue -u 2410 -g 2410 -d /var/lib/hue
RUN mkdir -p /var/lib/hue/ssl
#COPY resources/cacert.pem /var/lib/hue/ssl/
#COPY resources/cacert_key.pem /var/lib/hue/ssl/

# Fix hue request verify path: setting the ca bundle path as global env variable
ENV  REQUESTS_CA_BUNDLE /var/lib/hue/ssl/cacert.pem 

USER hue

#  Hue INSTALL   #

RUN tar -C /var/lib/hue -xzf /var/lib/hue-build.tar.gz --strip-components 1
RUN rm -f /var/lib/hue/desktop/conf/pseudo-distributed.ini
USER root
RUN rm -f /var/lib/hue-build.tar.gz
USER hue


COPY resources/hue_init.sh /var/lib/hue/


USER root
RUN chmod +x /var/lib/hue/hue_init.sh
USER hue

ENTRYPOINT ["./var/lib/hue/hue_init.sh"]