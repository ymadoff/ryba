
# Kafka Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'Kafka Broker # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.execute
        cmd: "su -l #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka stop'"
        if_exec: "su -l #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka status' | grep 'running with PID'"
      .then next
