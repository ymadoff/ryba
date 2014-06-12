---
title: 
layout: module
---

# HDFS Client

    hdfs_nn = require './hdfs_nn'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/core'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
      {static_host, realm} = ctx.config.hdp
      # Required
      ctx.config.hdp.hdfs_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'
      ctx.config.hdp.hdfs_site['dfs.namenode.kerberos.principal'] ?= "nn/#{static_host}@#{realm}"

    module.exports.push name: 'HDP HDFS Client # Configuration', callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs_site} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: hdfs_site
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HDFS Client # HA', callback: (ctx, next) ->
      {hadoop_conf_dir, ha_client_config} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: ha_client_config
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HDFS Client # Check', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs_site, test_user} = ctx.config.hdp
      port = hdfs_site['dfs.datanode.address']?.split('.')[1] or 1019
      # # DataNodes must all be started
      # datanodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_dn'
      # ctx.waitIsOpen datanodes, port, (err) ->
      #   return next err if err
      # User "test" should be created
      ctx.waitForExecution mkcmd.test(ctx, "hdfs dfs -test -d /user/#{test_user.name}"), (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f /user/#{test_user.name}/#{ctx.config.host}-hdfs; then exit 2; fi
          hdfs dfs -touchz /user/#{test_user.name}/#{ctx.config.host}-hdfs
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          next err, if executed then ctx.OK else ctx.PASS


