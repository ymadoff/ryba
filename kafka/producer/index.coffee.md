
# Kafka Producer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      {kafka} = ctx.config.ryba
      ks_ctxs = ctx.contexts 'ryba/kafka/broker', require('../broker').configure
      brokers = for ks_ctx in ks_ctxs
        "#{ks_ctx.config.host}:#{ks_ctx.config.ryba.kafka.broker.port}"
      # Configuration
      kafka.producer ?= {}
      kafka.producer['compression.codec'] ?= 'snappy'
      kafka.producer['metadata.broker.list'] ?= brokers.join ','
      kafka.producer.log4j ?= {}
      kafka.producer.log4j['log4j.rootLogger'] ?= 'WARN, stdout'
      kafka.producer.log4j['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      kafka.producer.log4j['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      kafka.producer.log4j['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'

    module.exports.push commands: 'check', modules: 'ryba/kafka/producer/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/producer/install'
      'ryba/kafka/producer/check'
    ]
