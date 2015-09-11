
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka/broker/wait'
    # module.exports.push require('./index').configure

## Check Messages

Make sure the broker is listening. The default port is "9092".

    module.exports.push
      name: 'Kafka Consumer # Check Messages'
      label_true: 'CHECKED'
      if: -> @has_module 'ryba/kafka/producer'
      handler: ->
        {kafka} = @config.ryba
        brokers = @contexts('ryba/kafka/broker').map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker['port']}"
        ).join ','
        @execute
          cmd: """
          (
            echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --broker-list #{brokers} \
              --topic test
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --topic test \
            --zookeeper #{kafka.consumer['zookeeper.connect']} --from-beginning --max-messages 1 | grep 'hello front1'
          """
