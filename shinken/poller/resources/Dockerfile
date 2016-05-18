# Dockerfile for running shinken test scripts
# `docker build -t ryba/shinken-poller-executor .`
FROM centos:latest

### PACKAGES ###
# add epel repo
RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm

RUN yum clean all && yum swap fakesystemd systemd
RUN yum -y update
# Install additionnal tools
RUN yum -y install sudo krb5-workstation wget libev libev-devel nmap-ncat jwhois cronie
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
#RUN curl -L http://cpanmin.us | perl - --sudo App::cpanminus
RUN wget http://nodejs.org/dist/latest/node-v6.2.0-linux-x64.tar.xz
RUN sudo tar --strip-components 1 -xJf node-v* -C /usr/local

### LAYOUT ###
ARG user=shinken
RUN useradd -ms /bin/bash $user
RUN echo "$user        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

ARG unprivileged_krb5_principal
ARG privileged_krb5_principal
RUN echo "01 */9 * * * root /usr/bin/kinit $privileged_krb5_principal -kt /etc/security/keytabs/crond.privileged.keytab" > /etc/cron.d/1kinit
RUN echo "01 */9 * * * $user /usr/bin/kinit $unprivileged_krb5_principal -kt /etc/security/keytabs/crond.unprivileged.keytab" >> /etc/cron.d/1kinit

USER $user
WORKDIR /home/$user
# Downloading shinken-plugins
RUN git clone https://github.com/pierrotws/shinken-plugins plugins
WORKDIR plugins
RUN rm -rf .git*
CMD sudo crond -n
