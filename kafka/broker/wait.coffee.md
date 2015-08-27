
# HBase Master Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

    module.exports.push name: 'Kafka Broker # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      ctx.wait_connect
        servers: for ks_ctx in ctx.contexts 'ryba/kafka/broker', require('./index').configure
          host: ks_ctx.config.host
          port: ks_ctx.config.ryba.kafka.broker['port']
      .then next
