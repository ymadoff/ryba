
# Kafka Consumer Install

    module.exports = header: 'Kafka Consumer Install', handler: ->
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

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
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

Update the file "consumer.properties" with the properties defined by the
"ryba.kafka.consumer" configuration.

      @file
        header: 'Consumer Properties'
        target: "#{kafka.consumer.conf_dir}/consumer.properties"
        write: for k, v of kafka.consumer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Logging

Update the different log4j properties files

      @file
        header: 'Tools Log4j'
        target: "#{kafka.consumer.conf_dir}/tools-log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
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
        header: 'Test Log4j'
        target: "#{kafka.consumer.conf_dir}/test-log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Kerberos

Write JAAS File for client configuration

      @file.jaas
        header: 'Consumer JAAS'
        if: kafka.consumer.env['KAFKA_KERBEROS_PARAMS']?
        target: "#{kafka.consumer.conf_dir}/kafka-client.jaas"
        content:
          KafkaClient:
            useTicketCache: true
            serviceName: kafka.user.name
          Client:
            useTicketCache: true
            serviceName: kafka.user.name
        uid: kafka.user.name
        gid: kafka.group.name

## Environment

 Exports JAAS configuration to consumer JVM properties.

      @file
        header: 'Environment'
        target: "#{kafka.consumer.conf_dir}/kafka-env.sh"
        write: for k, v of kafka.consumer.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        eof: true
## SSL

  Imports broker's CA to trustore

      @java_keystore_add
        if: kafka.consumer.config['ssl.truststore.location']?
        header: 'SSL Client'
        keystore:   kafka.consumer.config['ssl.truststore.location']
        storepass:   kafka.consumer.config['ssl.truststore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true

## Dependencies

    quote = require 'regexp-quote'
