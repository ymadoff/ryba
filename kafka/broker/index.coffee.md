
# Kafka Broker

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        hdp: 'ryba/hdp'
        hdf: 'ryba/hdf'
        zookeeper: 'ryba/zookeeper/server'
        hadoop_core: 'ryba/hadoop/core'
        zoo_server: 'ryba/zookeeper/server'
        ranger_admin: 'ryba/ranger/admin'
        ganglia: 'ryba/ganglia/collector'
      configure: [
        'ryba/kafka/broker/configure'
        'ryba/ranger/plugins/kafka/configure'
      ]
      commands: 
        'install': [
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
