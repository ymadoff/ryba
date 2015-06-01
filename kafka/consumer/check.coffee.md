
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/kafka/broker/wait'
    module.exports.push require('./index').configure

## Check Messages

Make sure the broker is listening. The default port is "9092".

    module.exports.push name: 'Kafka Consumer # Check Messages', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      return next() unless ctx.has_module 'ryba/kafka/producer'
      brokers = ctx.contexts('ryba/kafka/broker', require('../broker').configure).map( (ctx) ->
        "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker['port']}"
      ).join ','
      quorum = kafka.consumer['zookeeper.connect']
      ctx.execute
        cmd: """
        (
          echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
            --broker-list #{brokers} \
            --topic test
        )&
        /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
          --topic test \
          --zookeeper #{quorum} --from-beginning --max-messages 1 | grep 'hello front1'
        """
      .then next
