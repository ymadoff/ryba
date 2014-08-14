---
title: 
layout: module
---

# HDFS Client

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/core'

    module.exports.push module.exports.configure = (ctx) ->
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

    module.exports.push 'ryba/hadoop/hdfs_client_check'

## Module dependencies

    hdfs_nn = require './hdfs_nn'
    mkcmd = require './lib/mkcmd'


