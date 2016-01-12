# Dockerfile for running shinken test scripts
# `docker build -t ryba/shinken-poller-executor .`
FROM centos:latest

# add epel repo
RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

RUN yum clean all && yum swap fakesystemd systemd
RUN yum -y update
# Install additionnal tools
RUN yum -y install git make sudo perl perl-devel perl-CPAN gcc perl-libwww-perl perl-DBD-MySQL mysql-devel
# Disable require tty for sudo
RUN sed -i 's/Defaults.*requiretty/# Defaults requiretty/g' /etc/sudoers
RUN yum -y install python-pip
# Install CPANM
RUN curl -L http://cpanmin.us | perl - --sudo App::cpanminus

WORKDIR /opt
# Downloading harisekhon lib
RUN git clone https://github.com/harisekhon/lib.git
WORKDIR /opt/lib
# If ssl doesn't work with self-signed CA, please uncomment following line
RUN touch .use_net_ssl
# Build it
RUN make 
