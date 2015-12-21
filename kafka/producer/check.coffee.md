
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka/broker/wait'

## Check TCP

Make sure the broker are listening. The default port is "9092".

    module.exports.push header: 'Kafka Producer # Check TCP', label_true: 'CHECKED', handler: ->
      {kafka} = @config.ryba
      execute = kafka.producer.config['metadata.broker.list'].split(',').map (broker) ->
        [host, port] = broker.split ':'
        cmd: "echo > /dev/tcp/#{host}/#{port}"
      @execute execute

## Check Messages

Make sure the broker are listening. The default port is "9092".

    module.exports.push header: 'Kafka Producer # Check Messages', label_true: 'CHECKED', handler: ->
      {kafka} = @config.ryba
      return unless @has_module 'ryba/kafka/consumer'
      brokers = @contexts('ryba/kafka/broker').map (ctx) ->
        "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.config['port']}"
      zookeeper_quorum = @contexts('ryba/kafka/consumer')[0].config.ryba.kafka.consumer.config['zookeeper.connect']
      @execute
        cmd: """
        (
          echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
            --broker-list #{brokers.join ','} \
            --topic test
        )&
        /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
          --topic test \
          --zookeeper #{zookeeper_quorum} --from-beginning --max-messages 1 | grep 'hello front1'
        """
