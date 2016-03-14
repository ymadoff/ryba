
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
        'ryba/lib/hdp_select'
        'ryba/lib/write_jaas'
        'ryba/commons/krb5_user'
        'masson/core/krb5_client/wait'
        'ryba/kafka/broker/install'
        'ryba/zookeeper/server/wait'
        'ryba/kafka/broker/start'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/kafka/broker/wait'
        'ryba/kafka/broker/check'
      ]
      'check': [
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/kafka/broker/wait'
        'ryba/kafka/broker/check'
      ]
      'start': [
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/kafka/broker/start'
      ]
      'stop': [
        'ryba/kafka/broker/stop'
      ]
      'status': [
        'ryba/kafka/broker/status'
      ]
      'wait': [
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/kafka/broker/wait'
      ]
