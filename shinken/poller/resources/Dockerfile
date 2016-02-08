# Dockerfile for running shinken test scripts
# `docker build -t ryba/shinken-poller-executor .`
FROM centos:latest

# add epel repo
RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

RUN yum clean all && yum swap fakesystemd systemd
RUN yum -y update
# Install additionnal tools
RUN yum -y install sudo krb5-workstation wget libev libev-devel jwhois cronie
# Install dev tools
RUN yum -y install git gcc gcc-c++ make snappy-devel openssl-devel expat-devel cyrus-sasl-devel mysql-devel
# Install php
RUN yum -y install php
# Install PERL
RUN yum -y install perl perl-devel perl-CPAN perl-libwww-perl perl-DBD-MySQL
# Install python
RUN yum -y install python-setuptools python-pip python-devel
# Disable require tty for sudo
RUN sed -i 's/Defaults.*requiretty/# Defaults requiretty/g' /etc/sudoers
# Install CPANM
RUN curl -L http://cpanmin.us | perl - --sudo App::cpanminus
RUN wget http://nodejs.org/dist/latest/node-v5.5.0-linux-x64.tar.xz
RUN sudo tar --strip-components 1 -xJf node-v* -C /usr/local
WORKDIR /opt
# Downloading shinken-plugins
RUN git clone https://github.com/pierrotws/shinken-plugins
WORKDIR /opt/shinken-plugins
# Install CRON
RUN echo '0 */9 * * * /usr/bin/kinit $KRB5_PRINCIPAL -kt /etc/security/keytabs/crond.keytab' > /etc/cron.d/1keytab
CMD crond -n
