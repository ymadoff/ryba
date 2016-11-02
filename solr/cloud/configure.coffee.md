

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
      {ryba} = @config
      [java_ctx] = @contexts 'masson/commons/java', require("#{__dirname}/../../node_modules/masson/commons/java/configure").handler
      java = java_ctx.config.java
      {solr, realm} = ryba ?= {}
      solr.user ?= {}
      solr.user = name: solr.user if typeof solr.user is 'string'
      solr.user.name ?= 'solr'
      solr.user.home ?= "/var/#{solr.user.name}/data"
      solr.user.system ?= true
      solr.user.comment ?= 'Solr User'
      solr.user.groups ?= 'hadoop'
      # Group
      solr.group ?= {}
      solr.group = name: solr.group if typeof solr.group is 'string'
      solr.group.name ?= 'solr'
      solr.group.system ?= true
      solr.user.gid ?= solr.group.name
      solr.cloud ?= {}
      solr.cloud.version ?= '5.5.0'
      solr.cloud.host ?= @config.host # need for rendering xml
      solr.cloud.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{solr.cloud.version}/solr-#{solr.cloud.version}.tgz"
      solr.cloud.root_dir ?= '/usr'
      solr.cloud.install_dir ?= "#{solr.cloud.root_dir}/solr-cloud/#{solr.cloud.version}"
      solr.cloud.latest_dir ?= "#{solr.cloud.root_dir}/solr-cloud/current"
      solr.cloud.latest_dir = '/opt/lucidworks-hdpsearch/solr' if solr.cloud.source is 'HDP'
      solr.cloud.pid_dir ?= '/var/run/solr'
      solr.cloud.log_dir ?= '/var/log/solr'
      solr.cloud.conf_dir ?= '/etc/solr-cloud/conf'


## Core Conf
Ryba installs solrcloud with a single instance (one core).
However, once installed, the user can start easily several instances for 
differents cores ( and so with different ports).

      # Layout
      solr.cloud.port ?= 8983
      solr.cloud.env ?= {}
      zk_hosts = @contexts 'ryba/zookeeper/server', require("#{__dirname}/../../zookeeper/server/configure").handler
      solr.cloud.zk_connect = zk_hosts.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
      solr.cloud.zk_node ?= 'solr'
      solr.cloud.zkhosts = "#{solr.cloud.zk_connect}/#{solr.cloud.zk_node}"
      solr.cloud.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      solr.cloud.lock_type = 'native'

## Fix Conf
Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` is named `zkCredientialsProvider`

      solr.cloud.conf_source = if (solr.cloud.version.split('.')[0] < 6) or (solr.cloud.source is 'HDP')
      then "#{__dirname}/../resources/cloud/solr_5.xml.j2"
      else "#{__dirname}/../resources/cloud/solr_6.xml.j2"

## Security

      solr.cloud.security ?= {}
      solr.cloud.security["authentication"] ?= {}
      solr.cloud.security["authentication"]['class'] ?= if  @config.ryba.security is 'kerberos'
      then 'org.apache.solr.security.KerberosPlugin'
      else 'solr.BasicAuthPlugin'
      if @config.ryba.security is 'kerberos'
        # Kerberos
        solr.cloud.admin_principal ?= "#{solr.user.name}@#{realm}"
        solr.cloud.admin_password ?= 'solr123'
        solr.cloud.principal ?= "#{solr.user.name}/#{@config.host}@#{realm}"
        solr.cloud.keytab ?= '/etc/security/keytabs/solr.service.keytab'
        solr.cloud.spnego ?= {}
        solr.cloud.spnego.principal ?= "HTTP/#{@config.host}@#{@config.ryba.realm}"
        solr.cloud.spnego.keytab ?= '/etc/security/keytabs/spnego.service.keytab'
        solr.cloud.auth_opts ?= {}
        solr.cloud.auth_opts['solr.kerberos.cookie.domain'] ?= "#{@config.host}"
        solr.cloud.auth_opts['java.security.auth.login.config'] ?= "#{solr.cloud.conf_dir}/solr-server.jaas"
        solr.cloud.auth_opts['solr.kerberos.principal'] ?= solr.cloud.spnego.principal
        solr.cloud.auth_opts['solr.kerberos.keytab'] ?= solr.cloud.spnego.keytab
        solr.cloud.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
        # Authentication
        #Acls
        #https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
        # ACL are available from solr 5.3 version (HDP verseion has 5.2 (June-2016))
        # Configure roles & acl only on one host
        if @contexts('ryba/solr/cloud')[0].config.host is @config.host
          if solr.cloud.source isnt 'HDP'
            if not /^[0-5].[0-2]/.test solr.cloud.version # version < 5.3
              solr.cloud.security["authorization"] ?= {}
              solr.cloud.security["authorization"]['class'] ?= 'solr.RuleBasedAuthorizationPlugin'
              solr.cloud.security["authorization"]['permissions'] ?= []
              # solr.cloud.security["authorization"]['permissions'].push name: 'security-edit' , role: 'admin' #define new role
              # solr.cloud.security["authorization"]['permissions'].push name: 'read' , role: 'reader' #define new role
              solr.cloud.security["authorization"]['permissions'].push name: 'all' , role: 'manager' #define new role
              solr.cloud.security["authorization"]['user-role'] ?= {}
              solr.cloud.security["authorization"]['user-role']["#{solr.cloud.admin_principal}"] ?= 'manager'
              for host in @contexts('ryba/solr/cloud').map( (c)->c.config.host)
                solr.cloud.security["authorization"]['user-role']["#{solr.user.name}/#{host}@#{@config.ryba.realm}"] ?= 'manager'
                solr.cloud.security["authorization"]['user-role']["HTTP/#{host}@#{@config.ryba.realm}"] ?= 'manager'

## SSL

      solr.cloud.ssl ?= {}
      solr.cloud.ssl.enabled ?= true
      solr.cloud.ssl_trustore_path ?= "#{solr.cloud.conf_dir}/trustore"
      solr.cloud.ssl_trustore_pwd ?= 'solr123'
      solr.cloud.ssl_keystore_path ?= "#{solr.cloud.conf_dir}/keystore"
      solr.cloud.ssl_keystore_pwd ?= 'solr123'

### Environment and Zookeeper ACL
      
      solr.cloud.zk_opts ?= {}
      if java?
        solr.cloud.env['SOLR_JAVA_HOME'] ?= java.java_home
      solr.cloud.env['SOLR_HOST'] ?= @config.host
      solr.cloud.env['ZK_HOST'] ?= solr.cloud.zkhosts
      solr.cloud.env['SOLR_HEAP'] ?= "512m"
      solr.cloud.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if solr.cloud.ssl.enabled
        solr.cloud.env['SOLR_SSL_KEY_STORE'] ?= solr.cloud.ssl_keystore_path
        solr.cloud.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= solr.cloud.ssl_keystore_pwd
        solr.cloud.env['SOLR_SSL_TRUST_STORE'] ?= solr.cloud.ssl_trustore_path
        solr.cloud.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= solr.cloud.ssl_trustore_pwd
        solr.cloud.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'
      if ryba.security is 'kerberos'
        solr.cloud.env['SOLR_AUTHENTICATION_CLIENT_CONFIGURER'] ?= 'org.apache.solr.client.solrj.impl.Krb5HttpClientConfigurer'
        # Zookeeper ACLs
        # https://cwiki.apache.org/confluence/display/solr/ZooKeeper+Access+Control
        # solr.cloud.zk_opts['zkCredentialsProvider'] ?= 'org.apache.solr.common.cloud.DefaultZkCredentialsProvider'
        # solr.cloud.zk_opts['zkACLProvider'] ?= 'org.apache.solr.common.cloud.SaslZkACLProvider'
        # solr.cloud.zk_opts['solr.authorization.superuser'] ?= solr.user.name #default to solr
        # solr.cloud.env['SOLR_ZK_CREDS_AND_ACLS'] ?= 'org.apache.solr.common.cloud.SaslZkACLProvider'
      else
        #d
      solr.cloud.zk_opts['zkCredentialsProvider'] ?= 'org.apache.solr.common.cloud.VMParamsSingleSetCredentialsDigestZkCredentialsProvider'
      solr.cloud.zk_opts['zkACLProvider'] ?= 'org.apache.solr.common.cloud.VMParamsAllAndReadonlyDigestZkACLProvider'
      solr.cloud.zk_opts['zkDigestUsername'] ?= solr.user.name
      solr.cloud.zk_opts['zkDigestPassword'] ?= 'solr123'
        # solr.cloud.zk_opts['zkDigestReadonlyUsername'] ?= auser
        # solr.cloud.zk_opts['zkDigestReadonlyPassword'] ?= 'solr123'

### Java version
Solr 6.0 is compiled with java 1.8.
So it must be run with jdk 1.8.
The `solr.cloud.jre_home` configuration allow a specific java version to be used by 
solr zkCli script

      solr.cloud.jre_home ?= java.jre_home if java?

### Configure HDFS
[Configure][solr-hdfs] Solr to index document using hdfs, and document stored in HDFS.

      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn' , require('../../hadoop/hdfs_nn/configure').handler
      if nn_ctxs.length > 0
        solr.cloud.hdfs ?= {}
        solr.cloud.hdfs.home ?=  "hdfs://#{nn_ctxs[0].config.ryba.core_site['fs.defaultFS']}/user/#{solr.user.name}"
        solr.cloud.hdfs.blockcache_enabled ?= 'true'
        solr.cloud.hdfs.blockcache_slab_count ?= '1'
        solr.cloud.hdfs.blockcache_direct_memory_allocation ?= 'false'
        solr.cloud.hdfs.blockcache_blocksperbank ?= 16384
        solr.cloud.hdfs.blockcache_read_enabled ?= 'true'
        solr.cloud.hdfs.blockcache_write_enabled ?= false 
        solr.cloud.hdfs.nrtcachingdirectory_enable ?= true
        solr.cloud.hdfs.nrtcachingdirectory_maxmergesizemb ?= '16'
        solr.cloud.hdfs.nrtcachingdirectory_maxcachedmb ?= '192'
        solr.cloud.hdfs.security_kerberos_enabled ?= if @config.ryba.security is 'kerberos' then true else fase
        solr.cloud.hdfs.security_kerberos_keytabfile ?= solr.cloud.keytab
        solr.cloud.hdfs.security_kerberos_principal ?= solr.cloud.principal
        # instruct solr to use hdfs as home dir
        solr.cloud.dir_factory = 'solr.HdfsDirectoryFactory'
        solr.cloud.lock_type = 'hdfs'




## Dependencies

    path = require 'path'

[solr-krb5]:https://cwiki.apache.org/confluence/display/solr/Kerberos+Authentication+Plugin
[solr-ssl]: https://cwiki.apache.org/confluence/display/solr/Enabling+SSL#EnablingSSL-RunSolrCloudwithSSL
[solr-auth]: https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
[solr-hdfs]: http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/
