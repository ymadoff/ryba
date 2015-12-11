
# Kafka Broker

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure
Example:

```json
{
  "ryba": {
    "kafka": {
      "broker": {
        "heapsize": 1024
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      kafka = ctx.config.ryba.kafka ?= {}
      # Layout
      kafka.conf_dir ?= '/etc/kafka/conf'
      # Group
      kafka.group = name: kafka.group if typeof kafka.group is 'string'
      kafka.group ?= {}
      kafka.group.name ?= 'kafka'
      kafka.group.system ?= true
      # User
      kafka.user ?= {}
      kafka.user = name: kafka.user if typeof kafka.user is 'string'
      kafka.user.name ?= kafka.group.name
      kafka.user.system ?= true
      kafka.user.comment ?= 'Kafka User'
      kafka.user.home = "/var/lib/#{kafka.user.name}"
      kafka.user.gid = kafka.group.name
      # ZooKeeper Quorun
      zoo_ctxs = ctx.contexts 'ryba/zookeeper/server', require('../../zookeeper/server').configure
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      # Configuration
      kafka.broker ?= {}
      kafka.broker['heapsize'] ?= '1024'
      kafka.broker.config ?= {}
      kafka.broker.config['port'] ?= '9092'
      kafka.broker.config['log.dirs'] ?= '/var/kafka'  # Comma-separated, default is "/tmp/kafka-logs"
      kafka.broker.config['log.dirs'] = kafka.broker['log.dirs'].join ',' if Array.isArray kafka.broker['log.dirs']
      kafka.broker.config['zookeeper.connect'] ?= zookeeper_quorum
      kafka.broker.config['log.retention.hours'] ?= '168'
      hosts = ctx.contexts('ryba/kafka/broker').map (ctx) -> ctx.config.host
      kafka.broker.config['num.partitions'] ?= hosts.length # Default number of log partitions per topic, default is "2"
      for host, i in hosts
        kafka.broker.config['broker.id'] ?= "#{i}" if host is ctx.config.host
      kafka.broker.env ?= {}
      # A more agressive configuration for production is provided here:
      # http://docs.confluent.io/1.0.1/kafka-rest/docs/deployment.html#jvm
      kafka.broker.env['KAFKA_HEAP_OPTS'] ?= "-Xmx#{kafka.broker['heapsize']}m -Xms#{kafka.broker['heapsize']}m"
      # Avoid console verbose ouput in a non-rotated kafka.out file
      # kafka.broker.env['KAFKA_LOG4J_OPTS'] ?= "-Dlog4j.configuration=file:$base_dir/../config/log4j.properties -Dkafka.root.logger=INFO, kafkaAppender"
      kafka.broker.env['KAFKA_LOG4J_OPTS'] ?= ""
      kafka.broker.log4j ?= {}
      kafka.broker.log4j['log4j.rootLogger'] ?= '${kafka.root.logger}'
      kafka.broker.log4j['log4j.additivity.kafka'] ?= "false"
      # Push user and group configuration to consumer and producer
      # for csm_ctx in ctx.contexts ['ryba/kafka/consumer', 'ryba/kafka/producer']
      #   csm_ctx.config.ryba ?= {}
      #   csm_ctx.config.ryba.kafka ?= {}
      #   csm_ctx.config.ryba.kafka.user ?= kafka.user
      #   csm_ctx.config.ryba.kafka.group ?= kafka.group


    module.exports.push commands: 'check', modules: 'ryba/kafka/broker/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/broker/install'
      'ryba/kafka/broker/start'
      'ryba/kafka/broker/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/kafka/broker/start'

    module.exports.push commands: 'status', modules: 'ryba/kafka/broker/status'

    module.exports.push commands: 'stop', modules: 'ryba/kafka/broker/stop'
