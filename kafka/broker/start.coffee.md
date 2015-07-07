
# Kafka Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'Kafka Broker # Start', label_true: 'STARTED', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.execute
        cmd: "su -l #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka start'"
        if_exec: "su -l #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka status' | grep 'not running'"
      .then next
