
# Hadoop HDFS SecondaryNameNode Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_snn').configure

    module.exports.push name: 'HDFS SNN # Start', label_true: 'STARTED', handler: (ctx, next) ->
      lifecycle.snn_start ctx, next

    # module.exports.push name: 'HDFS SNN # Wait', handler: (ctx, next) ->
    #   [host, port] = hdfs.site['dfs.namenode.secondary.http-address'].split ':'
    #   ctx.waitIsOpen host, port, next
