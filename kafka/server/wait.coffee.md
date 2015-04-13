
# HBase Master Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn_wait'

    module.exports.push name: 'Kafka Server # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      ks_ctxs = ctx.contexts 'ryba/kafka/server', require('./index').configure
      servers = for ks_ctx in ks_ctxs
        host: ks_ctx.config.host, port: ks_ctx.config.ryba.kafka.server['port']
      ctx.waitIsOpen servers, next

