
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/kafka/broker/wait'
    module.exports.push require('./index').configure

## Check TCP

Make sure the server is listening. The default port is "9092".

    module.exports.push name: 'Kafka Producer # Check TCP', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      execute = kafka.producer['metadata.broker.list'].split(',').map (broker) ->
        [host, port] = broker.split ':'
        cmd: "echo > /dev/tcp/#{host}/#{port}"
      ctx.execute execute, next

## Check Messages

Make sure the server is listening. The default port is "9092".

    module.exports.push name: 'Kafka Producer # Check Messages', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      return next() unless ctx.has_module 'ryba/kafka/consumer'
      brokers = ctx.contexts('ryba/kafka/server', require('../server').configure).map( (ctx) ->
        "#{ctx.config.host}:#{ctx.config.ryba.kafka.server['port']}"
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
