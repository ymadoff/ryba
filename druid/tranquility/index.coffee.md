
# Tranquility Server

[Tranquility] helps you send real-time event streams to Druid and handles 
partitioning, replication, service discovery, and schema rollover, seamlessly 
and without downtime.  You only have to define your Druid schema.

If you have a program that generates a stream, then you can push that stream 
directly into Druid in real-time. With this approach, Tranquility is embedded 
in your data-producing application. Tranquility comes with bindings for the 
Storm and Samza stream processors. It also has a direct API that can be used 
from any JVM-based program, such as Spark Streaming or a Kafka consumer.

For examples and more information, please see the [Tranquility README][readme].

[Tranquility]: http://druid.io/docs/0.9.1.1/ingestion/stream-ingestion.html#server
[readme]: https://github.com/druid-io/tranquility

    module.exports = ->
      'prepare':
        'ryba/druid/tranquility/prepare'
      'configure':
        'ryba/druid/tranquility/configure'
      'install': [
        'masson/commons/java'
        'ryba/druid/tranquility/install'
        'ryba/druid/tranquility/start'
      ]
      'start':
        'ryba/druid/tranquility/start'
      # 'status':
      #   'ryba/druid/tranquility/status'
      # 'stop':
      #   'ryba/druid/tranquility/stop'
