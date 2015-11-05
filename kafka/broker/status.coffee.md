
# Kafka Broker Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Kafka Broker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      {kafka} = @config.ryba
      @execute
        cmd: """
        if su -l #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka status' | grep 'not running'; then
          exit 3;
        fi
        """
        code_skipped: 3
