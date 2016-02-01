
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka/broker/wait'

## Check Messages

Check Message by writing to a test topic on the PLAINTEXT channel.

    module.exports.push
      header: 'Kafka Consumer # Check PLAINTEXT'
      label_true: 'CHECKED'
      if: -> @has_module 'ryba/kafka/producer'
      handler: ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('PLAINTEXT') == -1
        {kafka} = @config.ryba
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.ports['PLAINTEXT']}"
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
            --zookeeper #{kafka.consumer.config['zookeeper.connect']} --from-beginning --max-messages 1 | grep 'hello front1'
          """
