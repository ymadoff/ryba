
# HBase Master Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

    module.exports.push name: 'Kafka Broker # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      ks_ctxs = ctx.contexts 'ryba/kafka/broker', require('./index').configure
      brokers = for ks_ctx in ks_ctxs
        host: ks_ctx.config.host, port: ks_ctx.config.ryba.kafka.broker['port']
      ctx.waitIsOpen brokers, next
