
# Kafka Producer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../lib/commons').configure ctx
      {kafka} = ctx.config.ryba
      ks_ctxs = ctx.contexts 'ryba/kafka/server', require('../server').configure
      brokers = for ks_ctx in ks_ctxs
        "#{ks_ctx.config.host}:#{ks_ctx.config.ryba.kafka.server.port}"
      # Configuration
      kafka.producer ?= {}
      kafka.producer['compression.codec'] ?= 'snappy'
      kafka.producer['metadata.broker.list'] ?= brokers.join ','

    module.exports.push commands: 'check', modules: 'ryba/kafka/producer/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/producer/install'
      'ryba/kafka/producer/check'
    ]