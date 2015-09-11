
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
      knox.topologies ?= {}
      topology = knox.topologies[ctx.config.ryba.nameservice] ?= {}
      topology.providers ?= {}
      topology.providers.Default ?= role: 'identity-assertion'
      topology.providers.static ?=
        role: 'hostmap'
        enabled: false
      topology.providers.haProvider ?=
        role: 'ha'
        enabled: false
        config: WEBHDFS: 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
      ### Services ###
      topology.services ?= {}
      # Namenode
      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn'
      if nn_ctxs.length
        [nn_ctx] = nn_ctxs 
        topology.services['namenode'] ?= nn_ctx.config.ryba.core_site['fs.defaultFS']
      # WebHDFS
        topology.services['webhdfs'] ?= for nn_ctx in nn_ctxs
          path.join nn_ctx.config.ryba.hdfs.site["dfs.namenode.https-address.#{nn_ctx.config.ryba.nameservice}.#{nn_ctx.config.shortname}"], 'webhdfs'
      # Jobtracker
      rm_ctxs = ctx.contexts 'ryba/hadoop/yarn_rm'
      if rm_ctxs.length
        [rm_ctx] = rm_ctxs
        rm_shortname = if rm_ctxs.length > 1 then ".#{rm_ctx.config.shortname}" else ''    
        rm_address = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address#{rm_shortname}"]
        topology.services['jobtracker'] ?= "rpc://#{rm_address}" if rm_address?
      # WebHCat
      webhcat_ctxs = ctx.contexts 'ryba/hive/webhcat'
      if webhcat_ctxs.length
        [webhcat_ctx] = webhcat_ctxs
        host = webhcat_ctx.config.host 
        port = webhcat_ctx.config.ryba.webhcat.site['templeton.port']
        topology.services['webhcat'] ?= "http://#{host}:#{port}/templeton"
      # Oozie
      oozie_ctxs = ctx.contexts 'ryba/oozie/server'
      if oozie_ctxs.length
        [oozie_ctx] = oozie_ctxs
        topology.services['oozie'] ?= oozie_ctx.config.ryba.oozie.site['oozie.base.url']
      # WebHBase
      stargate_ctxs = ctx.contexts 'ryba/hbase/rest'
      if stargate_ctxs.length
        [stargate_ctx] = stargate_ctxs
        host = stargate_ctx.config.host
        port = stargate_ctx.config.ryba.hbase.site['hbase.rest.port']
        topology.services['webhbase'] ?= "http://#{host}:#{port}"
      # Thrift
      hive_ctxs = ctx.contexts 'ryba/hive/thrift'
      if hive_ctxs.length
        [hive_ctx] = hive_ctxs
        host = hive_ctx.config.host
        port = hive_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
        topology.services['hive'] ?= "http://#{host}:#{port}/cliservice"

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