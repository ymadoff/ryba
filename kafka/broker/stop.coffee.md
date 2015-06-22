
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


To emtpy a topic, please run on a broker node
```bash
/usr/hdp/current/kafka-broker/bin/kafka-run-class.sh kafka.admin.DeleteTopicCommand \
--topic <your_topic> --zookeeper <zookeeper_quorum>
```
