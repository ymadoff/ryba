
# Kafka Producer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = ->
      'configure': [
        'ryba/kafka/producer/configure'
      ]
      'install': [
         'ryba/lib/hdp_select'
         'ryba/lib/write_jaas'
         'ryba/kafka/producer/install'
         'ryba/zookeeper/server/wait'
         'ryba/kafka/broker/wait'
         'ryba/kafka/producer/check'
      ]
      'check': [
        'ryba/zookeeper/server/wait'
        'ryba/kafka/broker/wait'
        'ryba/kafka/producer/check'
      ]
