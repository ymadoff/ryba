
# Knox

The Apache Knox Gateway is a REST API gateway for interacting with Apache Hadoop
clusters. The gateway provides a single access point for all REST interactions
with Hadoop clusters.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'

## Configure

    module.exports.configure = (ctx) ->
      knox = ctx.config.ryba.knox ?= {}
      # Load configurations
      knox.conf_dir ?= '/etc/knox/conf'
      # User
      knox.user = name: knox.user if typeof knox.user is 'string'
      knox.user ?= {}
      knox.user.name ?= 'knox'
      knox.user.system ?= true
      knox.user.comment ?= 'Knox Gateway User'
      knox.user.home ?= '/var/lib/knox'
      # Group
      knox.group = name: knox.group if typeof knox.group is 'string'
      knox.group ?= {}
      knox.group.name ?= 'knox'
      knox.group.system ?= true
      knox.user.gid = knox.group.name
      # Kerberos
      knox.krb5_user ?= {}
      knox.krb5_user.principal ?= "#{knox.user.name}/#{ctx.config.host}@#{ctx.config.ryba.realm}"
      knox.krb5_user.keytab ?= '/etc/security/keytabs/knox.service.keytab'
      # Security
      knox.master_secret ?= 'knox_master_secret_123'
      # Configuration
      knox.site ?= {}
      knox.site['gateway.port'] ?= '8443'
      knox.site['gateway.path'] ?= 'gateway'
      knox.site['java.security.krb5.conf'] ?= '/etc/krb5.conf'
      knox.site['java.security.auth.login.config'] ?= "#{knox.conf_dir}/knox.jaas"
      knox.site['gateway.hadoop.kerberos.secured'] ?= 'true'
      knox.site['sun.security.krb5.debug'] ?= 'true'
      # Calculate Services config values for default topology
      webhcat_ctxs = ctx.contexts 'ryba/hive/webhcat', require('../hive/webhcat').configure
      # require('../hadoop/hdfs_nn').configure hdfs_ctx
      # console.log require('util').inspect hdfs_ctx.config.ryba.hdfs
      # webhcat_host = ctx.host_with_module 'ryba/hive/webhcat'
      # webhcat_port = webhcat.site['templeton.port']
      # hbase_hosts = ctx.hosts_with_module 'ryba/hbase/master'
      # hive_hosts = ctx.hosts_with_module 'ryba/hive/hcatalog'
      # hive_ctx = ctx.hosts[hive_hosts[0]]
      # require('../hive/hcatalog').configure hive_ctx
      # hive_mode = hive_ctx.config.ryba.hive.site['hive.server2.transport.mode']
      # throw Error "Invalid property \"hive.server2.transport.mode\", expect \"http\"" unless hive_mode is 'http'
      # hive_port = hive_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
      # knox.services ?= {}
      # knox.services['namenode'] ?=
      # knox.services['jobtracker'] ?= "rpc://#{rm_address}"
      # knox.services['webhdfs'] ?= "https://#{webhdfs_host}:50470/webhdfs"
      # knox.services['webhcat'] ?= "http://#{webhcat_host}:#{webhcat_port}/templeton"
      # knox.services['oozie'] ?= "#{oozie.site['oozie.base.url']}"
      # knox.services['webhbase'] ?= "http://#{hbase_host}:60080" if hbase_host
      # knox.services['hive'] ?= "http://#{hive_host}:#{hive_port}/cliservice" if hive_host
      knox.topologies ?= {}
      topology = knox.topologies[ctx.config.ryba.nameservice] ?= {}
      topology.providers ?= {}
      topology.providers.ShiroProvider ?=
        role: 'authentication'
        config:
          'sessionTimeout': 30
          'main.ldapRealm': 'org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm'
          'main.ldapContextFactory': 'org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory'
          'main.ldapRealm.contextFactory': '$ldapContextFactory'
          'main.ldapRealm.userDnTemplate': 'uid={0},ou=people,dc=hadoop,dc=apache,dc=org'
          'main.ldapRealm.contextFactory.url': 'ldap://localhost:33389'
          'main.ldapRealm.contextFactory.authenticationMechanism': 'simple'
          'urls./**':'authcBasic'
      topology.providers.Default ?= role: 'identity-assertion'
      topology.providers.static ?=
        role: 'hostmap'
        config:
          localhost: 'sandbox,sandbox.hortonworks.com'
      topology.providers.haProvider ?=
        role: 'ha'
        config: WEBHDFS: 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
      ### Services ###
      topology.services ?= {}
      # Namenode
      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn', require('../hadoop/hdfs_nn').configure
      if nn_ctxs.length
        topology.services['namenode'] ?= nn_ctxs[0].config.ryba.core_site['fs.defaultFS']
      # WebHDFS
        topology.services['webhdfs'] ?= path.join nn_ctx.config.ryba.hdfs.site["dfs.namenode.https-address.#{ryba.nameservice}.#{nn_ctx.config.shortname}"], 'webhdfs' for nn_ctx in nn_ctxs
      # Jobtracker
      rm_ctxs = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      if rm_ctxs.length
        rm_shortname = if rm_ctxs.length > 1 then ".#{rm_ctxs[0].config.shortname}" else ''    
        rm_address = rm_ctxs[0].config.ryba.yarn.site["yarn.resourcemanager.address#{rm_shortname}"]
        topology.services['jobtracker'] ?= "rpc://#{rm_address}" if rm_address?
      # WebHCat
      if nn_ctxs.length
        host = webhcat_ctxs[0].config.host if nn_ctxs.length
        port = webhcat_ctxs[0].config.ryba.webhcat.site['templeton.port']
        knox.services['webhcat'] ?= "http://#{host}:#{port}/templeton"
      # Oozie
      oozie_ctxs = ctx.contexts 'ryba/oozie/server', require('../oozie/server').configure
      if oozie_ctxs.length
        knox.services['oozie'] ?= oozie_ctxs[0].config.ryba.oozie.site['oozie.base.url']
      # WebHBase
      stargate_ctxs = 
      # knox.services['webhbase'] ?= "http://#{hbase_host}:60080" if hbase_host
      # Thrift
      knox.services['hive'] ?= "http://#{hive_host}:#{hive_port}/cliservice" if hive_host
        
    module.exports.push commands: 'check', modules: 'ryba/knox/check'

    module.exports.push commands: 'install', modules: [
      'ryba/knox/install'
      #'ryba/knox/start'
      #'ryba/knox/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/knox/start'

    module.exports.push commands: 'stop', modules: 'ryba/knox/stop'

    module.exports.push commands: 'status', modules: 'ryba/knox/status'

## Dependencies

    path = require 'path'