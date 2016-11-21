
# Configure Solr Cloud cluster on docker

This module configures the servers to be able to run different solrCloud cluster in 
docker containers. The configuration is made in two steps:
- The first is to create host level configuration as we would do without docker
The host level configuration will be shared by the different containers running 
on the same host.
- The second step consists to configure each SolrCloud cluster  on the container level
by looping through each on of it and configuring the different properties.
These properties are unique to each container, depending on the cluster/host it 
belongs to.
For now we supports only (at the cluster level) only one container by host.


Solr accepts differents sources:
 - HDP to use HDP lucidworks repos

```cson
ryba:
  solr: 
    source: 'HDP'
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
```
 - apache community edition to use the official release:   
 in this case you can choose the version

```cson
ryba:
  solr: 
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
    version: '6.0.0'
    source: 'http://mirrors.ircam.fr/pub/apache/lucene/solr/6.0.0/solr-6.0.0.tgz'
```

    module.exports = ->
      {java, ryba} = @config
      {solr, realm} = ryba ?= {}
      solr.user ?= {}
      solr.user = name: solr.user if typeof solr.user is 'string'
      solr.user.name ?= 'solr'
      solr.user.home ?= "/var/#{solr.user.name}/data"
      solr.user.system ?= true
      solr.user.comment ?= 'Solr User'
      solr.user.groups ?= 'hadoop'
      solr.user.gid ?= 'solr'
      # Group
      solr.group ?= {}
      solr.group = name: solr.group if typeof solr.group is 'string'
      solr.group.name ?= 'solr'
      solr.group.system ?= true
      # User Limits
      solr.user.limits ?= {}
      solr.user.limits.nofile ?= 64000
      solr.user.limits.nproc ?= true
      solr.cloud_docker ?= {}
      solr.cloud_docker.version ?= '5.5.0'
      solr.cloud_docker.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{solr.cloud_docker.version}/solr-#{solr.cloud_docker.version}.tgz"
      solr.cloud_docker.root_dir ?= '/usr'
      solr.cloud_docker.install_dir ?= "#{solr.cloud_docker.root_dir}/solr-cloud/#{solr.cloud_docker.version}"
      solr.cloud_docker.latest_dir ?= "#{solr.cloud_docker.root_dir}/solr-cloud/current"
      solr.cloud_docker.latest_dir = '/opt/lucidworks-hdpsearch/solr' if solr.cloud_docker.source is 'HDP'
      solr.cloud_docker.pid_dir ?= '/var/run/solr'
      solr.cloud_docker.log_dir ?= '/var/log/solr'
      solr.cloud_docker.conf_dir ?= '/etc/solr-cloud-docker/conf'
      solr.cloud_docker.build ?= {}
      solr.cloud_docker.build.dir ?= "#{@config.mecano.cache_dir}/solr"
      solr.cloud_docker.build.image ?= "ryba/solr"
      solr.cloud_docker.build.tar ?= "solr_image.tar"
      solr.cloud_docker.build.source ?= "#{solr.cloud_docker.build.dir}/#{solr.cloud_docker.build.tar}"
      solr.cloud_docker.docker_compose_version ?= '1'

## Core Conf

      # Layout
      solr.cloud_docker.log_dir ?= '/var/log/solr'
      solr.cloud_docker.pid_dir ?= '/var/run/solr'
      solr.cloud_docker.env ?= {}
      zk_hosts = @contexts 'ryba/zookeeper/server'
      solr.cloud_docker.zk_connect = zk_hosts.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
      solr.cloud_docker.zkhosts = "#{solr.cloud_docker.zk_connect}/solr"
      solr.cloud_docker.zk_node = "/solr"
      solr.cloud_docker.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      solr.cloud_docker.lock_type = 'native'

## Fix Conf
Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` was named `zkCredientialsProvider`

      solr.cloud_docker.conf_source = if (solr.cloud_docker.version.split('.')[0] < 6) or (solr.cloud_docker.source is 'HDP')
      then "#{__dirname}/../resources/cloud/solr_5.xml.j2"
      else "#{__dirname}/../resources/cloud/solr_6.xml.j2"      
      
## Security

      solr.cloud_docker.security ?= {}
      solr.cloud_docker.security["authentication"] ?= {}
      solr.cloud_docker.security["authentication"]['class'] ?= if  @config.ryba.security is 'kerberos'
      then 'org.apache.solr.security.KerberosPlugin'
      else 'solr.BasicAuthPlugin'
      if @config.ryba.security is 'kerberos'
        # Kerberos
        solr.admin_principal ?= "#{solr.user.name}@#{realm}"
        solr.admin_password ?= 'solr123'
        solr.cloud_docker.admin_principal ?= solr.admin_principal
        solr.cloud_docker.admin_password ?= solr.admin_password
        solr.cloud_docker.principal ?= "#{solr.user.name}/#{@config.host}@#{realm}"
        solr.cloud_docker.keytab ?= '/etc/security/keytabs/solr.service.keytab'
        solr.cloud_docker.spnego ?= {}
        solr.cloud_docker.spnego.principal ?= "HTTP/#{@config.host}@#{@config.ryba.realm}"
        solr.cloud_docker.spnego.keytab ?= '/etc/security/keytabs/spnego.service.keytab'
        solr.cloud_docker.auth_opts ?= {}
        solr.cloud_docker.auth_opts['solr.kerberos.cookie.domain'] ?= "#{@config.host}"
        solr.cloud_docker.auth_opts['java.security.auth.login.config'] ?= "#{solr.cloud_docker.conf_dir}/solr-server.jaas"
        solr.cloud_docker.auth_opts['solr.kerberos.principal'] ?= solr.cloud_docker.spnego.principal
        solr.cloud_docker.auth_opts['solr.kerberos.keytab'] ?= solr.cloud_docker.spnego.keytab
        solr.cloud_docker.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
        # Authentication

## SSL

      solr.cloud ?= {}
      solr.cloud.port ?= 8893
      solr.cloud_docker.ssl ?= {}
      solr.cloud_docker.ssl.enabled ?= true
      solr.cloud_docker.ssl_truststore_path ?= "#{solr.cloud_docker.conf_dir}/truststore"
      solr.cloud_docker.ssl_truststore_pwd ?= 'solr123'
      solr.cloud_docker.ssl_keystore_path ?= "#{solr.cloud_docker.conf_dir}/keystore"
      solr.cloud_docker.ssl_keystore_pwd ?= 'solr123'

## Swarn Config

      if @config.mecano.swarm
        solr.cloud_docker.swarm_conf ?=
          host: "tcp://#{@config.host}:#{solr.cloud_docker.port ? 2376}"
          tlsverify:" "
          tlscacert: "/etc/docker/certs.d/ca.pem"
          tlscert: "/etc/docker/certs.d/cert.pem"
          tlskey: "/etc/docker/certs.d/key.pem"
      else
        solr.cloud_docker.swarm_conf = null

## Environment

      solr.cloud_docker.env['SOLR_JAVA_HOME'] ?= java.java_home
      solr.cloud_docker.env['SOLR_HOST'] ?= @config.host
      solr.cloud_docker.env['SOLR_PID_DIR'] ?= solr.cloud_docker.pid_dir
      solr.cloud_docker.env['SOLR_HEAP'] ?= "512m"
      solr.cloud_docker.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if solr.cloud_docker.ssl.enabled
        solr.cloud_docker.env['SOLR_SSL_KEY_STORE'] ?= solr.cloud_docker.ssl_keystore_path
        solr.cloud_docker.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= solr.cloud_docker.ssl_keystore_pwd
        solr.cloud_docker.env['SOLR_SSL_TRUST_STORE'] ?= solr.cloud_docker.ssl_truststore_path
        solr.cloud_docker.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= solr.cloud_docker.ssl_truststore_pwd
        solr.cloud_docker.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'#require client authentication  by using cert

      # configure all cluster present in conf/config.coffee solr configuration
      for name,config of solr.cloud_docker.clusters
        configure_solr_cluster @ , name,config

## Dependencies
    
    configure_solr_cluster = require './clusterize'
