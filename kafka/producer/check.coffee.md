
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka/broker/wait'
    # module.exports.push require('./index').configure

## Check TCP

Make sure the broker are listening. The default port is "9092".

    module.exports.push name: 'Kafka Producer # Check TCP', label_true: 'CHECKED', handler: ->
      {kafka} = @config.ryba
      execute = kafka.producer['metadata.broker.list'].split(',').map (broker) ->
        [host, port] = broker.split ':'
        cmd: "echo > /dev/tcp/#{host}/#{port}"
      @execute execute

## Check Messages

Make sure the broker are listening. The default port is "9092".

    module.exports.push name: 'Kafka Producer # Check Messages', label_true: 'CHECKED', handler: ->
      {kafka} = @config.ryba
      return next() unless @has_module 'ryba/kafka/consumer'
      brokers = @contexts('ryba/kafka/broker', require('../broker').configure).map( (ctx) ->
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
