
# Kafka Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/zookeeper/server/wait'

    module.exports.push header: 'Kafka Broker # Start', label_true: 'STARTED', handler: ->
      {kafka} = @config.ryba
      @execute
        cmd: "su - #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka start'"
        if_exec: "su - #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka status' | grep 'not running'"
