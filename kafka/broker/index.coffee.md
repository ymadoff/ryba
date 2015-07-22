
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
      require('../').configure ctx
      {kafka} = ctx.config.ryba
      # Configuration
      kafka.broker ?= {}
      # kafka.broker['host.name'] ?= '0.0.0.0'
      kafka.broker['port'] ?= '9092'
      kafka.broker['log.dirs'] ?= '/var/kafka'  # Comma-separated, default is "/tmp/kafka-logs"
      kafka.broker['log.dirs'] = kafka.broker['log.dirs'].join ',' if Array.isArray kafka.broker['log.dirs']
      kafka.broker['zookeeper.connect'] ?= ctx.config.ryba.core_site['ha.zookeeper.quorum']
      kafka.broker['log.retention.hours'] ?= '168'
      kafka.broker['heapsize'] ?= 1024
      hosts = ctx.hosts_with_module 'ryba/kafka/broker'
      kafka.broker['num.partitions'] ?= hosts.length # Default number of log partitions per topic, default is "2"
      for host, i in hosts
        kafka.broker['broker.id'] ?= "#{i}" if host is ctx.config.host
      kafka.broker.env ?= {}
      kafka.broker.env['KAFKA_HEAP_OPTS'] ?= "-Xmx#{kafka.broker['heapsize']}m -Xms#{kafka.broker['heapsize']}m"
      # Avoid console verbose ouput in a non-rotated kafka.out file
      kafka.broker.env['KAFKA_LOG4J_OPTS'] ?= "-Dlog4j.configuration=file:$base_dir/../config/log4j.properties -Dkafka.root.logger=INFO, kafkaAppender"
      kafka.broker.log4j ?= {}
      kafka.broker.log4j['log4j.rootLogger'] ?= '${kafka.root.logger}'
      kafka.broker.log4j['log4j.additivity.kafka'] ?= "false"


    module.exports.push commands: 'check', modules: 'ryba/kafka/broker/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/broker/install'
      'ryba/kafka/broker/start'
      'ryba/kafka/broker/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/kafka/broker/start'

    module.exports.push commands: 'status', modules: 'ryba/kafka/broker/status'

    module.exports.push commands: 'stop', modules: 'ryba/kafka/broker/stop'
