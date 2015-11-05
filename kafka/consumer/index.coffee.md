
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      {kafka} = ctx.config.ryba
      # ZooKeeper Quorun
      zoo_ctxs = ctx.contexts 'ryba/zookeeper/server', require('../../zookeeper/server').configure
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      ks_ctxs = ctx.contexts 'ryba/kafka/broker', require('../broker').configure
      kafka.conf_dir = ks_ctxs[0].config.ryba.kafka.conf_dir
      kafka.user ?= {}
      kafka.user[k] ?= v for k, v of ks_ctxs[0].config.ryba.kafka.user
      kafka.group ?= {}
      kafka.group[k] ?= v for k, v of ks_ctxs[0].config.ryba.kafka.group
      # console.log 'consumer', ks_ctxs[0].config.ryba.kafka, kafka.user
      # Configuration
      kafka.consumer ?= {}
      kafka.consumer.config ?= {}
      kafka.consumer.config['zookeeper.connect'] ?= zookeeper_quorum
      kafka.consumer.config['group.id'] ?= 'ryba-consumer-group'
      kafka.consumer.log4j ?= {}
      kafka.consumer.log4j['log4j.rootLogger'] ?= 'WARN, stdout'
      kafka.consumer.log4j['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      kafka.consumer.log4j['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      kafka.consumer.log4j['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'

    module.exports.push commands: 'check', modules: 'ryba/kafka/consumer/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/consumer/install'
      'ryba/kafka/consumer/check'
    ]
