
# Knox

The Apache Knox Gateway is a REST API gateway for interacting with Apache Hadoop
clusters. The gateway provides a single access point for all REST interactions
with Hadoop clusters.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'

    module.exports.push (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../hadoop/core').configure ctx
      require('../hadoop/yarn').configure ctx
      require('../hadoop/webhcat').configure ctx
      require('../hadoop/oozie_server').configure ctx
      {core_site, yarn_site, hive_site, webhcat_site, oozie_site} = ctx.config.ryba
      knox = ctx.config.knox ?= {}
      # Layout
      ctx.config.knox.knox_conf_dir ?= '/etc/knox/conf'
      # User
      ctx.config.knox.user = name: ctx.config.knox.user if typeof ctx.config.knox.user is 'string'
      ctx.config.knox.user ?= {}
      ctx.config.knox.user.name ?= 'knox'
      ctx.config.knox.user.system ?= true
      ctx.config.knox.user.gid ?= 'knox'
      ctx.config.knox.user.comment ?= 'Knox Gateway User'
      ctx.config.knox.user.home ?= '/var/lib/knox'
      # Group
      ctx.config.knox.group = name: ctx.config.knox.group if typeof ctx.config.knox.group is 'string'
      ctx.config.knox.group ?= {}
      ctx.config.knox.group.name ?= 'knox'
      ctx.config.knox.group.system ?= true
      # Security
      knox.master_secret ?= 'knox_master_secret_123'
      # Configuration
      knox.gateway_site ?= {}
      knox.gateway_site['gateway.port'] ?= '8443'
      knox.gateway_site['gateway.hadoop.kerberos.secured'] ?= 'true'
      # Services
      webhdfs_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      webhcat_host = ctx.host_with_module 'ryba/hive/webhcat'
      webhcat_port = webhcat_site['templeton.port']
      hbase_host = ctx.host_with_module 'ryba/hbase/master'
      hive_host = ctx.host_with_module 'ryba/hive/server'
      hive_ctx = ctx.hosts[hive_host]
      require('../hive/server').configure hive_ctx
      hive_mode = hive_ctx.config.ryba.hive_site['hive.server2.transport.mode']
      throw Error "Invalid property \"hive.server2.transport.mode\", expect \"http\"" unless hive_mode is 'http'
      hive_port = hive_ctx.config.ryba.hive_site['hive.server2.thrift.http.port']
      knox.services ?= {}
      knox.services['namenode'] ?= "#{core_site['fs.defaultFS']}"
      knox.services['jobtracker'] ?= "rpc://#{yarn_site['yarn.resourcemanager.address']}"
      knox.services['webhdfs'] ?= "http://#{webhdfs_hosts[0]}:50070/webhdfs"
      knox.services['webhcat'] ?= "http://#{webhcat_host}:#{webhcat_port}/templeton"
      knox.services['oozie'] ?= "#{oozie_site['oozie.base.url']}"
      knox.services['webhbase'] ?= "http://#{hbase_host}:60080" if hbase_host
      knox.services['hive'] ?= "http://#{hive_host}:#{hive_port}/cliservice" if hive_host


## IPTables

| Service        | Port  | Proto | Parameter       |
|----------------|-------|-------|-----------------|
| Gateway        | 9083  | http  | gateway.port    |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Knox # IPTables', handler: (ctx, next) ->
      {gateway_site} = ctx.config.knox
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: gateway_site['gateway.port'], protocol: 'tcp', state: 'NEW', comment: "Knox Gateway" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

    module.exports.push name: 'Knox # Service', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'knox'
      , next

    module.exports.push name: 'Knox # Master', handler: (ctx, next) ->
      {knox_conf_dir, gateway_site, master_secret} = ctx.config.knox
      ctx.fs.exists '/usr/lib/knox/data/security/master', (err, exists) ->
        return next err, false if err or exists
        ctx.ssh.shell (err, stream) ->
          return next err if err
          cmd = "su -l knox -c '/usr/lib/knox/bin/knoxcli.sh create-master'"
          ctx.log "Run #{cmd}"
          reentered = done = false
          stream.write "#{cmd}\n"
          stream.on 'data', (data, stderr) ->
            ctx.log[if stderr then 'err' else 'out'].write data
            data = data.toString()
            if done
              # nothing
            else if reentered
              done = true
              stream.end 'exit\n'
            else if /Enter master secret:/.test data
              stream.write "#{master_secret}\n"
            else if /Enter master secret again:/.test data
              stream.write "#{master_secret}\n"
              reentered = true
          stream.on 'exit', ->
            next null, true
          stream.pipe ctx.log.out
          stream.stderr.pipe ctx.log.err
      # su -l knox -c '$gateway_home/bin/knoxcli.sh create-master'
      # MySecret
      next()

    module.exports.push name: 'Knox # Configure', handler: (ctx, next) ->
      {knox_conf_dir, gateway_site} = ctx.config.knox
      ctx.hconfigure
        destination: "#{knox_conf_dir}/gateway-site.xml"
        properties: gateway_site
        merge: true
      , next

    module.exports.push name: 'Knox # Topology', handler: (ctx, next) ->
      {nameservice} = ctx.config.ryba
      {knox_conf_dir, gateway_site} = ctx.config.knox
      console.log "TODO: topology (disabled for now)"
      return next null, false
      ctx.remove
        destination: "#{knox_conf_dir}/topologies/sandbox.xml"
        not_if: nameservice is 'sandbox'
      , (err, removed) ->
        return next err if err
        ctx.hconfigure
          destination: "#{knox_conf_dir}/topologies/#{nameservice}.xml"
          properties: topology
          merge: true
        , next




