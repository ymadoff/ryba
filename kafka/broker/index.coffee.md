
# Kafka Broker

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports = ->
      'configure': [
        'ryba/commons/krb5_user'
        'ryba/kafka/broker/configure'
      ]
      'install': [
        'masson/core/iptables'
        'masson/core/krb5_client'
        'ryba/commons/krb5_user'
        'ryba/kafka/broker/install'
        'ryba/kafka/broker/start'
        'ryba/kafka/broker/check'
      ]
      'check':
        'ryba/kafka/broker/check'
      'start':
        'ryba/kafka/broker/start'
      'stop':
        'ryba/kafka/broker/stop'
      'status':
        'ryba/kafka/broker/status'
      'wait':
        'ryba/kafka/broker/wait'
