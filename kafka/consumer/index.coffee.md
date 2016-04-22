
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = ->
      'configure':
        'ryba/kafka/consumer/configure'
      'install': [
        'ryba/kafka/consumer/install'
        'ryba/kafka/consumer/check'
      ]
      'check':
        'ryba/kafka/consumer/check'
