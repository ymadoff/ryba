
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka/broker/wait'


## Check Messages

Check Message by writing to a test topic on the PLAINTEXT channel.

    module.exports.push header: 'Kafka Producer # Check Plaintext', label_true: 'CHECKED',
    handler: ->
      {kafka} = @config.ryba
      return unless @has_module 'ryba/kafka/consumer'
      ks_ctxs = @contexts 'ryba/kafka/broker'
      return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('PLAINTEXT') == -1
      brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
        "#{ctx.config.host}:#{ctx.config.ryba.kafka.ports['PLAINTEXT']}"
      ).join ','
      zookeeper_quorum = @contexts('ryba/kafka/consumer')[0].config.ryba.kafka.consumer.config['zookeeper.connect']
      @execute
        cmd: """
        (
          echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
            --broker-list #{brokers} \
            --topic test
        )&
        /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
          --topic test \
          --zookeeper #{zookeeper_quorum} --from-beginning --max-messages 1 | grep 'hello front1'
        """
