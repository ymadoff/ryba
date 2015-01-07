
# Hadoop HDFS Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/core'

    module.exports.push require('./hdfs_client').configure

    module.exports.push name: 'HDFS Client # Configuration', callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs_site} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: hdfs_site
        merge: true
        backup: true
      , next

    module.exports.push name: 'HDFS Client # HA', callback: (ctx, next) ->
      {hadoop_conf_dir, ha_client_config} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: ha_client_config
        merge: true
        backup: true
      , next

    module.exports.push 'ryba/hadoop/hdfs_client_check'

## Module dependencies

    hdfs_nn = require './hdfs_nn'
    mkcmd = require '../lib/mkcmd'


