
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = ->
      'configure': [
        'ryba/kafka/consumer/configure'
      ]
      'install': [
        'ryba/lib/hdp_select'
        'ryba/lib/write_jaas'
        'ryba/kafka/consumer/install'
        'ryba/zookeeper/server/wait'
        'ryba/kafka/broker/wait'
        'masson/core/krb5_client/wait'
        'ryba/kafka/consumer/check'
      ]
      'check': [
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/kafka/broker/wait'
        'ryba/kafka/consumer/check'
      ]
