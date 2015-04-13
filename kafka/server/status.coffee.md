
# Kafka Server Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'Kafka Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.execute
        cmd: """
        if su -l #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka status' | grep 'not running'; then
          exit 3;
        fi
        """
        code_skipped: 3
      , next
     








