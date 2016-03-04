
# Kafka Broker Start

    module.exports = header: 'Kafka Broker Start', label_true: 'STARTED', handler: ->

Start the Kafka Broker. You can also start the server manually with the
following two commands:

```
service kafka-broker start
su - kafka -c '/usr/hdp/current/kafka-broker/bin/kafka start'
```

      @service_start name: 'kafka-broker'
