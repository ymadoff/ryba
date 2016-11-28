# RUN HUE

FROM centos:6.6

Maintainer Lucas Bkian

# Yum #

RUN yum install -y wget tar python  krb5-libs krb5-workstation vim
RUN yum install -y libxslt-devel
RUN yum install -y mysql mysql-connector-java
RUN yum install -y snappy
RUN yum install -y python-devel
RUN yum install -y openssl-devel
RUN yum install -y libxslt-devel
RUN yum install -y cyrus-sasl-gssapi unzip

# Java #

WORKDIR /tmp
RUN curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-linux-x64.rpm"
RUN rpm -ivh jdk-8u101-linux-x64.rpm
ENV JAVA_HOME /usr/java/default

RUN curl  -k  -o solr.tar.gz  "{{ryba.solr.cloud_docker.source}}"
ENV JAVA_HOME /usr/java/default

RUN curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"
RUN unzip jce_policy-8.zip
RUN cp UnlimitedJCEPolicyJDK8/US_export_policy.jar /usr/java/default/jre/lib/security/US_export_policy.jar
RUN cp UnlimitedJCEPolicyJDK8/local_policy.jar /usr/java/default/jre/lib/security/local_policy.jar

# Layout #

RUN mkdir -p {{ryba.solr.user.home}}
RUN groupadd {{ryba.hadoop_group.name}} -g {{ryba.hadoop_group.gid}}
RUN groupadd {{ryba.solr.group.name}} -g {{ryba.solr.user.gid}}
RUN useradd {{ryba.solr.user.name}} -u {{ryba.solr.user.uid}} -g {{ryba.solr.group.gid}} -m -d {{ryba.solr.user.home}}
RUN usermod -a -G {{ryba.hadoop_group.name}},{{ryba.solr.group.name}} {{ryba.solr.user.name}}

# Install #

RUN mkdir -p {{ryba.solr.cloud_docker.install_dir}}
RUN tar -C {{ryba.solr.cloud_docker.install_dir}} -xzf /tmp/solr.tar.gz --strip-components 1
RUN ln -s {{ryba.solr.cloud_docker.install_dir}} {{ryba.solr.cloud_docker.latest_dir}}
RUN mkdir -p {{ryba.solr.cloud_docker.conf_dir}}
RUN ln -s {{ryba.solr.cloud_docker.latest_dir}}/conf {{ryba.solr.cloud_docker.conf_dir}}
RUN rm -rf {{ryba.solr.cloud_docker.latest_dir}}/bin/solr.in.sh
RUN ln -s {{ryba.solr.cloud_docker.conf_dir}}/solr.in.sh  {{ryba.solr.cloud_docker.latest_dir}}/bin/solr.in.sh

RUN mkdir -p {{ryba.solr.cloud_docker.pid_dir}}
RUN chown {{ryba.solr.user.name}}:{{ryba.solr.group.name}} -R {{ryba.solr.cloud_docker.pid_dir}}
RUN mkdir -p {{ryba.solr.cloud_docker.log_dir}}
RUN chown {{ryba.solr.user.name}}:{{ryba.solr.group.name}} -R {{ryba.solr.cloud_docker.log_dir}}
RUN chown {{ryba.solr.user.name}}:{{ryba.solr.group.name}} -R {{ryba.solr.user.home}}
RUN ln -s {{ryba.solr.cloud_docker.conf_dir}}/solr.xml {{ryba.solr.user.home}}/solr.xml 


RUN chown {{ryba.solr.user.name}}:{{ryba.solr.group.name}} -R {{ryba.solr.cloud_docker.install_dir}}

COPY docker_entrypoint.sh /docker_entrypoint.sh
RUN chmod +x /docker_entrypoint.sh
RUN chown {{ryba.solr.user.name}}:{{ryba.solr.group.name}} /docker_entrypoint.sh

USER root
RUN rm -f /tmp/solr.tar.gz

RUN echo 'ZONE="Europe/Paris"'> /etc/sysconfig/clock
RUN ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN rm -f /jdk-8u101-linux-x64.rpm

USER {{ryba.solr.user.name}}
WORKDIR {{ryba.solr.user.home}}
ENV TERM=xterm-256color

CMD ["./docker_entrypoint.sh"]
