
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = 
      use:
        kafka_broker: 'ryba/kafka/broker'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        kafka_producer: 'ryba/kafka/producer'
      configure: 'ryba/kafka/consumer/configure'
      commands:
        install: [
          'ryba/kafka/consumer/install'
          'ryba/kafka/consumer/check'
        ]
        check:
          'ryba/kafka/consumer/check'
