

## Configure
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

    module.exports = handler: ->
      {java, ryba} = @config
      {solr, realm} = ryba ?= {}
      solr.version ?= '5.5.0'
      solr.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{solr.version}/solr-#{solr.version}.tgz"
      solr.root_dir ?= '/usr'
      solr.install_dir ?= "#{solr.root_dir}/solr/#{solr.version}"
      solr.latest_dir ?= "#{solr.root_dir}/solr/current"
      solr.latest_dir = '/opt/lucidworks-hdpsearch/solr' if solr.source is 'HDP'
      solr.pid_dir ?= '/var/run/solr'
      solr.log_dir ?= '/var/log/solr'
      solr.conf_dir ?= '/etc/solr/conf'
      solr.user ?= {}
      solr.user = name: solr.user if typeof solr.user is 'string'
      solr.user.name ?= 'solr'
      solr.user.home ?= "#{path.join '/var/solr', 'data'}"
      solr.user.system ?= true
      solr.user.comment ?= 'Solr User'
      solr.user.groups ?= 'hadoop'
      # Group
      solr.group ?= {}
      solr.group = name: solr.group if typeof solr.group is 'string'
      solr.group.name ?= 'solr'
      solr.group.system ?= true
      solr.user.gid ?= solr.group.name

## Core Conf
Ryba install solr with one instance (one core) configured with a port.
However, once installed, the user can start easily several instances for differents cores.

      # Layout
      solr.mode ?= 'cloud'
      solr.port ?= 8983
      solr.env ?= {}
      zk_hosts = @contexts 'ryba/zookeeper/server', require("#{__dirname}/../../zookeeper/server/configure").handler
      solr.zk_connect = zk_hosts.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
      solr.zkhosts = "#{solr.zk_connect}/solr"
      solr.zk_node = "/solr"
      solr.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      solr.lock_type = 'native'

## Fix Conf
Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` is named `zkCredientialsProvider`

      solr.conf_source = if solr.version.split('.')[0] < 6 or solr.source is 'HDP'
      then "#{__dirname}/../resources/solr_5.xml.j2"
      else "#{__dirname}/../resources/solr_6.xml.j2"

## Security

      solr.security ?= {}
      solr.security["authentication"] ?= {}
      solr.security["authentication"]['class'] ?= if  @config.ryba.security is 'kerberos'
      then 'org.apache.solr.security.KerberosPlugin'
      else 'solr.BasicAuthPlugin'
      if @config.ryba.security is 'kerberos'
        # Kerberos
        solr.admin_principal ?= "#{solr.user.name}@#{realm}"
        solr.admin_password ?= 'solr123'
        solr.principal ?= "#{solr.user.name}/#{@config.host}@#{realm}"
        solr.keytab ?= '/etc/security/keytabs/solr.service.keytab'
        solr.spnego ?= {}
        solr.spnego.principal ?= "HTTP/#{@config.host}@#{@config.ryba.realm}"
        solr.spnego.keytab ?= '/etc/security/keytabs/spnego.service.keytab'
        solr.auth_opts ?= {}
        solr.auth_opts['solr.kerberos.cookie.domain'] ?= "#{@config.host}"
        solr.auth_opts['java.security.auth.login.config'] ?= "#{solr.conf_dir}/solr-server.jaas"
        solr.auth_opts['solr.kerberos.principal'] ?= solr.spnego.principal
        solr.auth_opts['solr.kerberos.keytab'] ?= solr.spnego.keytab
        solr.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
        # Authentication
        #Acls
        #https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
        if solr.source isnt 'HDP'
          if not /^[0-5].[0-2]/.test solr.version # version < 5.3
            solr.security["authorization"] ?= {}
            solr.security["authorization"]['class'] ?= 'solr.RuleBasedAuthorizationPlugin'
            solr.security["authorization"]['permissions'] ?= []
            solr.security["authorization"]['permissions'].push name: 'security-edit' , role: 'admin' #define new role
            solr.security["authorization"]['permissions'].push name: 'read' , role: 'reader' #define new role
            solr.security["authorization"]['permissions'].push name: 'all' , role: 'manager' #define new role
            solr.security["authorization"]['user-role'] ?= {}
            solr.security["authorization"]['user-role']["#{solr.principal}"] ?= 'manager'
            solr.security["authorization"]['user-role']["#{solr.spnego.principal}"] ?= 'reader'

## SSL

      solr.ssl ?= {}
      solr.ssl.enabled ?= true
      solr.ssl_trustore_path ?= "#{solr.conf_dir}/trustore"
      solr.ssl_trustore_pwd ?= 'solr123'
      solr.ssl_keystore_path ?= "#{solr.conf_dir}/keystore"
      solr.ssl_keystore_pwd ?= 'solr123'

### Environment

      solr.env['SOLR_JAVA_HOME'] ?= java.java_home
      solr.env['SOLR_HOST'] ?= @config.host
      solr.env['ZK_HOST'] ?= solr.zkhosts
      solr.env['SOLR_HEAP'] ?= "512m"
      solr.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if solr.ssl.enabled
        solr.env['SOLR_SSL_KEY_STORE'] ?= solr.ssl_keystore_path
        solr.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= solr.ssl_keystore_pwd
        solr.env['SOLR_SSL_TRUST_STORE'] ?= solr.ssl_trustore_path
        solr.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= solr.ssl_trustore_pwd
        solr.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'
      if ryba.security is 'kerberos'
        solr.env['SOLR_AUTHENTICATION_CLIENT_CONFIGURER'] ?= 'org.apache.solr.client.solrj.impl.Krb5HttpClientConfigurer'

### Java version
Solr 6.0 is compiled with java 1.8.
So it must be run jdk 1.8.
The `solr.jre_home` configuration allow a specific java version to be used by 
solr zkCli script

      solr.jre_home ?= java.jre_home

### Configure HDFS
[Configure][solr-hdfs] Solr to index document using hdfs, and document stored in HDFS.
      
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn' , require('../../hadoop/hdfs_nn/configure').handler
      if nn_ctxs.length > 0
        solr.hdfs ?= {}
        solr.hdfs.home ?=  "hdfs://#{nn_ctxs[0].config.ryba.core_site['fs.defaultFS']}/user/#{solr.user.name}"
        solr.hdfs.blockcache_enabled ?= 'true'
        solr.hdfs.blockcache_slab_count ?= '1'
        solr.hdfs.blockcache_direct_memory_allocation ?= 'false'
        solr.hdfs.blockcache_blocksperbank ?= 16384
        solr.hdfs.blockcache_read_enabled ?= 'true'
        solr.hdfs.blockcache_write_enabled ?= false 
        solr.hdfs.nrtcachingdirectory_enable ?= true
        solr.hdfs.nrtcachingdirectory_maxmergesizemb ?= '16'
        solr.hdfs.nrtcachingdirectory_maxcachedmb ?= '192'
        solr.hdfs.security_kerberos_enabled ?= if @config.ryba.security is 'kerberos' then true else fase
        solr.hdfs.security_kerberos_keytabfile ?= solr.keytab
        solr.hdfs.security_kerberos_principal ?= solr.principal
        # instruct solr to use hdfs as home dir
        solr.dir_factory = 'solr.HdfsDirectoryFactory'
        solr.lock_type = 'hdfs'
        
        
  

## Dependencies

    path = require 'path'

[solr-krb5]:https://cwiki.apache.org/confluence/display/solr/Kerberos+Authentication+Plugin
[solr-ssl]: https://cwiki.apache.org/confluence/display/solr/Enabling+SSL#EnablingSSL-RunSolrCloudwithSSL
[solr-auth]: https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
[solr-hdfs]: http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/
