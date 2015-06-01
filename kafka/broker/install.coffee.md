
# Kafka Broker Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/kafka'
    module.exports.push require('./index').configure

## IPTables

| Service      | Port  | Proto | Parameter          |
|--------------|-------|-------|--------------------|
| Kafka Broker | 9092  | http  | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Kafka Broker # IPTables', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.broker['port'], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Configure

Update the file "broker.properties" with the properties defined by the
"ryba.kafka.broker" configuration.

    module.exports.push name: 'Kafka Broker # Configure', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      write = for k, v of kafka.broker
        match: RegExp "^#{quote k}=.*$", 'mg'
        replace: "#{k}=#{v}"
        append: true
      ctx.write
        destination: "#{kafka.conf_dir}/broker.properties"
        write: write
        backup: true
        eof: true
      .then next

## Dependencies

    quote = require 'regexp-quote'
