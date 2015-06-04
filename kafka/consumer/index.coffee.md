
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      {kafka} = ctx.config.ryba
      # Configuration
      kafka.consumer ?= {}
      kafka.consumer['zookeeper.connect'] ?= ctx.config.ryba.core_site['ha.zookeeper.quorum']
      kafka.consumer['group.id'] ?= 'ryba-consumer-group'

    module.exports.push commands: 'check', modules: 'ryba/kafka/consumer/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/consumer/install'
      'ryba/kafka/consumer/check'
    ]
