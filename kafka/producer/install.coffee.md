
# Kafka Producer Install

    module.exports = header: 'Kafka Producer Install', handler: ->
      {kafka, ssl} = @config.ryba

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users & Groups

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

      @system.group kafka.group
      @system.user kafka.user

## Package

Install the Kafka producer package and set it to the latest version. Note, we
select the "kafka-broker" HDP directory. There is no "kafka-producer"
directories.

      @service
        name: 'kafka'
      @system.mkdir
        target: '/var/lib/kafka'
        uid: kafka.user.name
        gid: kafka.user.name
      @hdp_select
        name: 'kafka-broker'

## Configure

Update the file "server.properties" with the properties defined by the
"ryba.kafka.server" configuration.

      @file 
        header: 'Producer Properties'
        target: "#{kafka.producer.conf_dir}/producer.properties"
        write: for k, v of kafka.producer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Logging

      @file
        header: 'Log4j'
        target: "#{kafka.consumer.conf_dir}/log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @file
        header: 'Tools Log4j'
        target: "#{kafka.producer.conf_dir}/tools-log4j.properties"
        write: for k, v of kafka.producer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true


## Kerberos

      @file.jaas
        header: 'Producer JAAS'
        if: -> kafka.producer.env['KAFKA_KERBEROS_PARAMS']?
        target: "#{kafka.producer.conf_dir}/kafka-client.jaas"
        content:
          KafkaClient:
            useTicketCache: true
            serviceName: kafka.user.name
          Client:
            useTicketCache: true
            serviceName: kafka.user.name
        uid: kafka.user.name
        gid: kafka.group.name

## Env

 Exports JAAS configuration to producer JVM properties.

      @file
        header: 'Environment'
        target: "#{kafka.producer.conf_dir}/kafka-env.sh"
        write: for k, v of kafka.producer.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        eof: true

## SSL

  Imports broker's CA to trustore.

      @java_keystore_add
        header: 'SSL Client'
        if: -> kafka.producer.config['ssl.truststore.location']?
        keystore: kafka.producer.config['ssl.truststore.location']
        storepass: kafka.producer.config['ssl.truststore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true

## Dependencies

    quote = require 'regexp-quote'
