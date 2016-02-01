
# Kafka Producer Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/lib/hdp_select'
    module.exports.push 'ryba/lib/write_jaas'

## Users & Groups

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

    module.exports.push header: 'Kafka Producer # Users & Groups', handler: ->
      {kafka} = @config.ryba
      @group kafka.group
      @user kafka.user

## Package

Install the Kafka producer package and set it to the latest version. Note, we
select the "kafka-broker" HDP directory. There is no "kafka-producer"
directories.

    module.exports.push header: 'Kafka Producer # Package', handler: ->
      @service
        name: 'kafka'
      @hdp_select
        name: 'kafka-broker'

## Configure

Update the file "server.properties" with the properties defined by the
"ryba.kafka.server" configuration.

    module.exports.push header: 'Kafka Producer # Configure', handler: (options, next) ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.producer.conf_dir}/producer.properties"
        write: for k, v of kafka.producer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @write
        destination: "#{kafka.producer.conf_dir}/tools-log4j.properties"
        write: for k, v of kafka.producer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @then next

## Kerberos

    module.exports.push header: 'Kafka Producer # Kerberos', handler: ->
      {kafka} = @config.ryba
      @write_jaas
        destination: "#{kafka.producer.conf_dir}/kafka-client.jaas"
        content:
          KafkaClient:
            useTicketCache=true
        uid: kafka.user.name
        gid: kafka.group.name

## Env

 Exports JAAS configuration to producer JVM properties.

    module.exports.push header: 'Kafka Producer # Kerberos', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.producer.conf_dir}/kafka-env.sh"
        write: for k, v of kafka.producer.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        eof: true

## SSL

  Imports broker's CA to trustore.

    module.exports.push header: 'Kafka Consumer # SSL Client', handler: ->
      {kafka, ssl} = @config.ryba
      [ks_ctx] = @contexts 'ryba/kafka/broker'
      @java_keystore_add
        keystore: kafka.producer.config['ssl.truststore.location']
        storepass: kafka.producer.config['ssl.truststore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true

## Dependencies

    quote = require 'regexp-quote'
