
# HBase Master Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

    module.exports.push name: 'HBase Master # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      ctx.wait_connect
        servers: for hm_ctx in ctx.contexts 'ryba/hbase/master', require('./index').configure
          host: hm_ctx.config.host
          port: hm_ctx.config.ryba.hbase.site['hbase.master.port']
      .then next
