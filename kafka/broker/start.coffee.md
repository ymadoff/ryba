
# Kafka Broker Start

Start the Kafka Broker. You can also start the server manually with the
following two commands:

```
service kafka-broker start
su - kafka -c '/usr/hdp/current/kafka-broker/bin/kafka start'
```

    module.exports = header: 'Kafka Broker Start', label_true: 'STARTED', handler: ->

Wait for Kerberos and ZooKeeper.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'

Start the service.

      @service_start name: 'kafka-broker'
