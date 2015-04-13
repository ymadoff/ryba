
# Kafka Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/kafka/lib/commons'
    module.exports.push require('./index').configure

## IPTables

| Service      | Port  | Proto | Parameter          |
|--------------|-------|-------|--------------------|
| Kafka Server | 9092  | http  | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Kafka Server # IPTables', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.server['port'], protocol: 'tcp', state: 'NEW', comment: "Kafka Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Configure

Update the file "server.properties" with the properties defined by the
"ryba.kafka.server" configuration.

    module.exports.push name: 'Kafka Server # Configure', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      write = for k, v of kafka.server
        match: RegExp "^#{quote k}=.*$", 'mg'
        replace: "#{k}=#{v}"
        append: true
      ctx.write
        destination: "#{kafka.conf_dir}/server.properties"
        write: write
        backup: true
        eof: true
      , next

## Dependencies

    quote = require 'regexp-quote'
