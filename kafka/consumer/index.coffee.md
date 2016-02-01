
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      {kafka} = ctx.config.ryba ?= {}
      # ZooKeeper Quorun
      zoo_ctxs = ctx.contexts 'ryba/zookeeper/server', require('../../zookeeper/server').configure
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      ks_ctxs = ctx.contexts 'ryba/kafka/broker', require('../broker').configure
      kafka.user ?= {}
      kafka.user[k] ?= v for k, v of ks_ctxs[0].config.ryba.kafka.user
      kafka.group ?= {}
      kafka.group[k] ?= v for k, v of ks_ctxs[0].config.ryba.kafka.group
      # console.log 'consumer', ks_ctxs[0].config.ryba.kafka, kafka.user
      # Configuration
      kafka.consumer ?= {}
      kafka.consumer.conf_dir ?= '/etc/kafka/conf'
      kafka.consumer.config ?= {}
      kafka.consumer.config['zookeeper.connect'] ?= zookeeper_quorum
      kafka.consumer.config['group.id'] ?= 'ryba-consumer-group'
      kafka.consumer.log4j ?= {}
      kafka.consumer.log4j['log4j.rootLogger'] ?= 'WARN, stdout'
      kafka.consumer.log4j['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      kafka.consumer.log4j['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      kafka.consumer.log4j['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'

## SSL

      for protocol in ks_ctxs[0].config.ryba.kafka.broker.protocols
        continue unless ['SASL_SSL','SSL'].indexOf protocol > -1
        kafka.consumer.config['ssl.truststore.location'] ?= "#{kafka.consumer.conf_dir}/truststore"
        kafka.consumer.config['ssl.truststore.password'] ?= 'ryba123'
        kafka.consumer.config['security.protocol'] ?= 'SSL'
        # kafka.consumer.config['ssl.keystore.location'] ?= "#{kafka.consumer.conf_dir}/keystore"
        # kafka.consumer.config['ssl.keystore.password'] ?= 'ryba123'
        # kafka.consumer.config['ssl.key.password'] ?= 'ryba123'


## Kerberos

      kafka.consumer.env ?= {}
      kafka.consumer.env['KAFKA_KERBEROS_PARAMS'] ?= "-Djava.security.auth.login.config=#{kafka.consumer.conf_dir}/kafka-client.jaas"

    module.exports.push commands: 'check', modules: 'ryba/kafka/consumer/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/consumer/install'
      'ryba/kafka/consumer/check'
    ]
