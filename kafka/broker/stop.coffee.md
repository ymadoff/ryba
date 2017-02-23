
# Kafka Broker Start

Stop the Kafka Broker. You can also stop the server manually with the following
tow commands:

```
service kafka-broker stop
su -l kafka -c '/usr/hdp/current/kafka-broker/bin/kafka stop'
```

The file storing the PID is "/var/run/kafka/kafka.pid".

    module.exports = header: 'Kafka Broker Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'kafka-broker'
        if_exists: '/etc/init.d/kafka-broker'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', handler: ->
        return unless @config.ryba.clean_logs
        @system.execute
          cmd: 'rm /var/log/kafka/*'
          code_skipped: 1

To emtpy a topic, please run on a broker node
```bash
/usr/hdp/current/kafka-broker/bin/kafka-run-class.sh kafka.admin.DeleteTopicCommand \
--topic <your_topic> --zookeeper <zookeeper_quorum>
```
