
# Kafka Server

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../lib/commons').configure ctx
      {kafka} = ctx.config.ryba
      # Configuration
      kafka.server ?= {}
      # kafka.server['host.name'] ?= '0.0.0.0'
      kafka.server['port'] ?= '9092'
      kafka.server['log.dirs'] # Comma-separated, default is "/tmp/kafka-logs"
      kafka.server['num.partitions'] # Default number of log partitions per topic, default is "2"
      kafka.server['zookeeper.connect'] ?= ctx.config.ryba.core_site['ha.zookeeper.quorum']
      kafka.server['log.retention.hours'] ?= '168'
      hosts = ctx.hosts_with_module 'ryba/kafka/server'
      for host, i in hosts
        kafka.server['broker.id'] = "#{i}" if host is ctx.config.host

    module.exports.push commands: 'check', modules: 'ryba/kafka/server/check'

    module.exports.push commands: 'install', modules: [
      'ryba/kafka/server/install'
      'ryba/kafka/server/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/kafka/server/start'

    module.exports.push commands: 'status', modules: 'ryba/kafka/server/status'

    module.exports.push commands: 'stop', modules: 'ryba/kafka/server/stop'



