
# Hadoop HDFS Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/core'

    module.exports.push require('./hdfs_client').configure

    module.exports.push name: 'HDFS Client # Configuration', handler: (ctx, next) ->
      {hadoop_conf_dir, hdfs, hadoop_group} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      , next

    module.exports.push 'ryba/hadoop/hdfs_client_check'

## Module dependencies

    hdfs_nn = require './hdfs_nn'
    mkcmd = require '../lib/mkcmd'


