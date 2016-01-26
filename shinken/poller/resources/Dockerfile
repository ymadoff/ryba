# Dockerfile for running shinken test scripts
# `docker build -t ryba/shinken-poller-executor .`
FROM centos:latest

#inserer dans /usr/local/lib64/perl5/NetAddr/IP/InetBase.pm, 3eme ligne (avant use strict) :
#```
#use Socket;
#```
#Puis, installer Socket6 CPAN 

# add epel repo
RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

RUN yum clean all && yum swap fakesystemd systemd
RUN yum -y update
# Install additionnal tools
RUN yum -y install sudo krb5-workstation wget libev libev-devel jwhois
# Install dev tools
RUN yum -y install git gcc gcc-c++ make snappy-devel openssl-devel expat-devel cyrus-sasl-devel mysql-devel
# Install PERL
RUN yum -y install perl perl-devel perl-CPAN perl-libwww-perl perl-DBD-MySQL
# Install python
RUN yum -y install python-setuptools python-pip python-devel
# Disable require tty for sudo
RUN sed -i 's/Defaults.*requiretty/# Defaults requiretty/g' /etc/sudoers
# Install CPANM
RUN curl -L http://cpanmin.us | perl - --sudo App::cpanminus
WORKDIR /opt
# Downloading harisekhon nagios-plugins
RUN git clone https://github.com/pierrotws/shinken-plugins
WORKDIR /opt/shinken-plugins
RUN git submodule init
RUN git submodule update
# If ssl doesn't work with self-signed CA, please uncomment following lines
RUN touch lib/.use_net_ssl
RUN touch .use_net_ssl
# Build it
RUN make
RUN sed -i 's/use strict;/use Socket;\nuse strict;/' /usr/local/lib64/perl5/NetAddr/IP/InetBase.pm
RUN cpan Module::Socket6
# SSL insecure
ENV PERL_LWP_SSL_VERIFY_HOSTNAME 0
# Install CRON
RUN yum install -y cronie
RUN echo '0 */9 * * * /usr/bin/kinit $KRB5_PRINCIPAL /etc/security/keytabs/crond.keytab' > /etc/cron.d/1keytab
CMD crond -n
