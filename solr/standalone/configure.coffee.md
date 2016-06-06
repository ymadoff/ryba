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
      solr.single ?= {} 
      solr.single.version ?= '5.5.0'
      solr.single.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{solr.single.version}/solr-#{solr.single.version}.tgz"
      solr.single.root_dir ?= '/usr'
      solr.single.install_dir ?= "#{solr.single.root_dir}/solr/#{solr.single.version}"
      solr.single.latest_dir ?= "#{solr.single.root_dir}/solr/current"
      solr.single.latest_dir = '/opt/lucidworks-hdpsearch/solr' if solr.single.source is 'HDP'
      solr.single.pid_dir ?= '/var/run/solr'
      solr.single.log_dir ?= '/var/log/solr'
      solr.single.conf_dir ?= '/etc/solr/conf'


## Core Conf
Ryba installs solrcloud with a single instance (one core).
However, once installed, the user can start easily several instances for 
differents cores ( and so with different ports).

      # Layout
      solr.single.port ?= 8983
      solr.single.env ?= {}
        
      solr.single.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      solr.single.lock_type = 'native'

## Fix Conf
Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` is named `zkCredientialsProvider`

      solr.single.conf_source = if (solr.single.version.split('.')[0] < 6) or (solr.single.source is 'HDP')
      then "#{__dirname}/../resources/standalone/solr_5.xml.j2"
      else "#{__dirname}/../resources/standalone/solr_6.xml.j2"

## Security

      if  @config.ryba.security is 'kerberos'
        solr.single.principal ?= "#{solr.user.name}/#{@config.host}@#{realm}"
        solr.single.keytab ?= '/etc/security/keytabs/solr.single.service.keytab'
        

## SSL

      solr.single.ssl ?= {}
      solr.single.ssl.enabled ?= true
      solr.single.ssl_trustore_path ?= "#{solr.single.conf_dir}/trustore"
      solr.single.ssl_trustore_pwd ?= 'solr123'
      solr.single.ssl_keystore_path ?= "#{solr.single.conf_dir}/keystore"
      solr.single.ssl_keystore_pwd ?= 'solr123'

### Environment

      solr.single.env['SOLR_JAVA_HOME'] ?= java.java_home
      solr.single.env['SOLR_HOST'] ?= @config.host
      solr.single.env['SOLR_HEAP'] ?= "512m"
      solr.single.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if solr.single.ssl.enabled
        solr.single.env['SOLR_SSL_KEY_STORE'] ?= solr.single.ssl_keystore_path
        solr.single.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= solr.single.ssl_keystore_pwd
        solr.single.env['SOLR_SSL_TRUST_STORE'] ?= solr.single.ssl_trustore_path
        solr.single.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= solr.single.ssl_trustore_pwd
        solr.single.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'
      # if ryba.security is 'kerberos'
      #   solr.single.env['SOLR_AUTHENTICATION_CLIENT_CONFIGURER'] ?= 'org.apache.solr.client.solrj.impl.Krb5HttpClientConfigurer'

### Java version
Solr 6.0 is compiled with java 1.8.
So it must be run with jdk 1.8.
The `solr.single.jre_home` configuration allow a specific java version to be used by 
solr zkCli script

      solr.single.jre_home ?= java.jre_home

### Configure HDFS
[Configure][solr-hdfs] Solr to index document using hdfs, and document stored in HDFS.
      
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn' , require('../../hadoop/hdfs_nn/configure').handler
      if nn_ctxs.length > 0
        solr.single.hdfs ?= {}
        solr.single.hdfs.home ?=  "hdfs://#{nn_ctxs[0].config.ryba.core_site['fs.defaultFS']}/user/#{solr.user.name}"
        solr.single.hdfs.blockcache_enabled ?= 'true'
        solr.single.hdfs.blockcache_slab_count ?= '1'
        solr.single.hdfs.blockcache_direct_memory_allocation ?= 'false'
        solr.single.hdfs.blockcache_blocksperbank ?= 16384
        solr.single.hdfs.blockcache_read_enabled ?= 'true'
        solr.single.hdfs.blockcache_write_enabled ?= false 
        solr.single.hdfs.nrtcachingdirectory_enable ?= true
        solr.single.hdfs.nrtcachingdirectory_maxmergesizemb ?= '16'
        solr.single.hdfs.nrtcachingdirectory_maxcachedmb ?= '192'
        solr.single.hdfs.security_kerberos_enabled ?= if @config.ryba.security is 'kerberos' then true else fase
        solr.single.hdfs.security_kerberos_keytabfile ?= solr.single.keytab
        solr.single.hdfs.security_kerberos_principal ?= solr.single.principal
        # instruct solr to use hdfs as home dir
        solr.single.dir_factory = 'solr.HdfsDirectoryFactory'
        solr.single.lock_type = 'hdfs'
        
        
  

## Dependencies

    path = require 'path'

[solr-krb5]:https://cwiki.apache.org/confluence/display/solr/Kerberos+Authentication+Plugin
[solr-ssl]: https://cwiki.apache.org/confluence/display/solr/Enabling+SSL#EnablingSSL-RunSolrCloudwithSSL
[solr-auth]: https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
[solr-hdfs]: http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/
