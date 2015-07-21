
# Kafka Broker Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
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
        destination: "#{kafka.conf_dir}/server.properties"
        write: write
        backup: true
        eof: true
      .then next

Update the file kafka-server-start.sh (prefered to the general "kafka-env.sh" file) with the env variables defined by the
"ryba.kafka.env" configuration.

    module.exports.push name: 'Kafka Broker # Env', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.write
        destination: "#{kafka.conf_dir}/kafka-server-start.sh"
        write: for k, v of kafka.broker.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        eof: true
      ctx.write
        destination: "#{kafka.conf_dir}/log4j.properties"
        write: for k, v of kafka.broker.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      .then next

## Layout

Directories in which Kafka data is stored. Each new partition that is created
will be placed in the directory which currently has the fewest partitions.

    module.exports.push name: 'Kafka Broker # Layout', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.mkdir (
        destination: dir
        uid: kafka.user.name
        gid: kafka.group.name
        mode: 0o0750
        parent: true
      ) for dir in kafka.broker['log.dirs'].split ','
      ctx.then next

## Dependencies

    quote = require 'regexp-quote'
