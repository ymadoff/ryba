
# HBase Master Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

    module.exports.push header: 'Kafka Broker # Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for ks_ctx in @contexts 'ryba/kafka/broker'#, require('./index').configure
          host: ks_ctx.config.host
          port: ks_ctx.config.ryba.kafka.broker.config['port']
