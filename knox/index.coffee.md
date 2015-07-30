
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
      # require('masson/core/iptables').configure ctx
      # require('../hadoop/core').configure ctx
      # require('../hadoop/yarn_rm').configure ctx
      # require('../hive/webhcat').configure ctx
      # require('../oozie/server').configure ctx
      # {core_site, hive, webhcat, oozie} = ctx.config.ryba
      # Layout
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
      # Security
      knox.master_secret ?= 'knox_master_secret_123'
      # Configuration
      knox.site ?= {}
      knox.site['gateway.port'] ?= '8443'
      knox.site['gateway.hadoop.kerberos.secured'] ?= 'true'
      # # Services
      # rm_contexts = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      # rm_shortname = if rm_contexts.length > 1 then ".#{rm_contexts[0].config.shortname}" else ''
      # rm_address = rm_contexts[0].config.ryba.yarn.site["yarn.resourcemanager.address#{rm_shortname}"]
      #
      # [webhdfs_host] = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      # webhcat_host = ctx.host_with_module 'ryba/hive/webhcat'
      # webhcat_port = webhcat.site['templeton.port']
      # hbase_host = ctx.host_with_module 'ryba/hbase/master'
      # hive_host = ctx.host_with_module 'ryba/hive/hcatalog'
      # hive_ctx = ctx.hosts[hive_host]
      # require('../hive/hcatalog').configure hive_ctx
      # hive_mode = hive_ctx.config.ryba.hive.site['hive.server2.transport.mode']
      # throw Error "Invalid property \"hive.server2.transport.mode\", expect \"http\"" unless hive_mode is 'http'
      # hive_port = hive_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
      # knox.services ?= {}
      # knox.services['namenode'] ?= "#{core_site['fs.defaultFS']}"
      # knox.services['jobtracker'] ?= "rpc://#{rm_address}"
      # knox.services['webhdfs'] ?= "https://#{webhdfs_host}:50470/webhdfs"
      # knox.services['webhcat'] ?= "http://#{webhcat_host}:#{webhcat_port}/templeton"
      # knox.services['oozie'] ?= "#{oozie.site['oozie.base.url']}"
      # knox.services['webhbase'] ?= "http://#{hbase_host}:60080" if hbase_host
      # knox.services['hive'] ?= "http://#{hive_host}:#{hive_port}/cliservice" if hive_host


    module.exports.push commands: 'check', modules: 'ryba/knox/check'

    module.exports.push commands: 'install', modules: [
      'ryba/knox/install'
      #'ryba/knox/start'
      #'ryba/knox/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/knox/start'

    module.exports.push commands: 'stop', modules: 'ryba/knox/stop'

    module.exports.push commands: 'status', modules: 'ryba/knox/status'
