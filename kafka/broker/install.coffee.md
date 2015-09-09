
# Kafka Broker Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/kafka'
    module.exports.push require '../../lib/hdp_select'
    # module.exports.push require('./index').configure

## IPTables

| Service      | Port  | Proto | Parameter          |
|--------------|-------|-------|--------------------|
| Kafka Broker | 9092  | http  | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Kafka Broker # IPTables', handler: ->
      {kafka} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.broker['port'], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker" }
        ]
        if: @config.iptables.action is 'start'

## Package

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

    module.exports.push name: 'Kafka Consumer # Package', handler: ->
      @service
        name: 'kafka'
      @hdp_select
        name: 'kafka-broker'

## Configure

Update the file "broker.properties" with the properties defined by the
"ryba.kafka.broker" configuration.

    module.exports.push name: 'Kafka Broker # Configure', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.conf_dir}/server.properties"
        write: for k, v of kafka.broker
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

Update the file kafka-server-start.sh (prefered to the general "kafka-env.sh" file) with the env variables defined by the
"ryba.kafka.env" configuration.

    module.exports.push name: 'Kafka Broker # Env', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.conf_dir}/kafka-server-start.sh"
        write: for k, v of kafka.broker.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        eof: true
      @write
        destination: "#{kafka.conf_dir}/log4j.properties"
        write: for k, v of kafka.broker.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Layout

Directories in which Kafka data is stored. Each new partition that is created
will be placed in the directory which currently has the fewest partitions.

    module.exports.push name: 'Kafka Broker # Layout', handler: ->
      {kafka} = @config.ryba
      @mkdir (
        destination: dir
        uid: kafka.user.name
        gid: kafka.group.name
        mode: 0o0750
        parent: true
      ) for dir in kafka.broker['log.dirs'].split ','

## Dependencies

    quote = require 'regexp-quote'
