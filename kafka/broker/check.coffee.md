
# Kafka Broker Check

    module.exports = header: 'Kafka Broker Check', label_true: 'CHECKED', handler: ->
      {kafka} = @config.ryba

## Wait

      @call once: true, 'ryba/kafka/broker/wait'

## Check TCP

Make sure the broker is listening. The default port is "9092".

      @call header: 'Check TCP', label_true: 'CHECKED', ->
        for protocol in kafka.broker.protocols
          @system.execute
            cmd: "echo > /dev/tcp/#{@config.host}/#{kafka.broker.ports[protocol]}"
