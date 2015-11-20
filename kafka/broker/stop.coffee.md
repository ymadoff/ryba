
# Kafka Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

Stop the Kafka Broker. You can also stop the server manually with the following
command:

```
su -l kafka -c '/usr/hdp/current/kafka-broker/bin/kafka stop'
```

The file storing the PID is "/var/run/kafka/kafka.pid".

    module.exports.push header: 'Kafka Broker # Stop service', label_true: 'STOPPED', handler: ->
      {kafka} = @config.ryba
      @execute
        cmd: "su - #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka stop'"
        if_exec: "su - #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka status' | grep 'running with PID'"

## Stop Clean Logs

    module.exports.push header: 'Kafka Broker # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      {kafka} = @config.ryba
      @execute
        cmd: "su - #{kafka.user.name} -c '/usr/hdp/current/kafka-broker/bin/kafka clean'"
        code_skipped: 1
        if: @config.ryba.clean_logs
        if_exists: '/usr/hdp/current/kafka-broker/bin/kafka'
      @execute
        cmd: 'rm /var/log/kafka/*'
        code_skipped: 1
        if: @config.ryba.clean_logs

To emtpy a topic, please run on a broker node
```bash
/usr/hdp/current/kafka-broker/bin/kafka-run-class.sh kafka.admin.DeleteTopicCommand \
--topic <your_topic> --zookeeper <zookeeper_quorum>
```
