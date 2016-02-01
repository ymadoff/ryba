
# Kafka Producer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      {kafka} = ctx.config.ryba
      ks_ctxs = ctx.contexts 'ryba/kafka/broker', require('../broker').configure
      brokers = for ks_ctx in ks_ctxs
        "#{ks_ctx.config.host}:#{ks_ctx.config.ryba.kafka.broker.config.port}"
      kafka.user ?= {}
      kafka.user[k] ?= v for k, v of ks_ctxs[0].config.ryba.kafka.user
      kafka.group ?= {}
      kafka.group[k] ?= v for k, v of ks_ctxs[0].config.ryba.kafka.group
      #Configuration
      kafka.producer ?= {}
      kafka.producer.conf_dir ?= '/etc/kafka/conf'
      kafka.producer.config ?= {}
      kafka.producer.config['compression.codec'] ?= 'snappy'
      kafka.producer.config['metadata.broker.list'] ?= brokers.join ','
      kafka.producer.log4j ?= {}
      kafka.producer.log4j['log4j.rootLogger'] ?= 'WARN, stdout'
      kafka.producer.log4j['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      kafka.producer.log4j['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      kafka.producer.log4j['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'

## SSL

      for protocol in ks_ctxs[0].config.ryba.kafka.broker.protocols
        continue unless ['SASL_SSL','SSL'].indexOf protocol > -1
        kafka.producer.config['ssl.truststore.location'] ?= "#{kafka.producer.conf_dir}/truststore"
        kafka.producer.config['ssl.truststore.password'] ?= 'ryba123'
        kafka.producer.config['security.protocol'] ?= 'SSL'
        # No client ssl
        # kafka.producer.config['ssl.keystore.location'] ?= "#{kafka.producer.conf_dir}/keystore"
        # kafka.producer.config['ssl.keystore.password'] ?= 'ryba123'
        # kafka.producer.config['ssl.key.password'] ?= 'ryba123'



## Kerberos

      kafka.producer.env ?= {}
      kafka.producer.env['KAFKA_KERBEROS_PARAMS'] ?= "-Djava.security.auth.login.config=#{kafka.producer.conf_dir}/kafka-client.jaas"

    module.exports.push commands: 'check', modules: 'ryba/kafka/producer/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/producer/install'
      'ryba/kafka/producer/check'
    ]
