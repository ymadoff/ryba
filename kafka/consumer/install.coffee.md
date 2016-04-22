
# Kafka Consumer Install
    
    module.exports = header: 'Kafka Consumer Install', handler: ->
      {kafka, ssl} = @config.ryba

## Register

      @call once: true, 'ryba/lib/hdp_select'
      @call once: true, 'ryba/lib/write_jaas'

## Users & Groups

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

      @group kafka.group
      @user kafka.user

## Package

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @service
        name: 'kafka'
      @mkdir
        destination: '/var/lib/kafka'
        uid: kafka.user.name
        gid: kafka.user.name
      @hdp_select
        name: 'kafka-broker'

## Configure

Update the file "consumer.properties" with the properties defined by the
"ryba.kafka.consumer" configuration.

      @write
        header: 'Consumer Properties'
        destination: "#{kafka.consumer.conf_dir}/consumer.properties"
        write: for k, v of kafka.consumer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Logging

Update the different log4j properties files
    
      @write
        header: 'Tools Log4j'
        destination: "#{kafka.consumer.conf_dir}/tools-log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @write
        header: 'Log4j'
        destination: "#{kafka.consumer.conf_dir}/log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @write
        header: 'Test Log4j'
        destination: "#{kafka.consumer.conf_dir}/test-log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Kerberos

Write JAAS File for client configuration

      @write_jaas
        header: 'Consumer JAAS'
        if: kafka.consumer.env['KAFKA_KERBEROS_PARAMS']?
        destination: "#{kafka.consumer.conf_dir}/kafka-client.jaas"
        content:
          KafkaClient:
            useTicketCache: true
          Client:
            useTicketCache: true
        uid: kafka.user.name
        gid: kafka.group.name
        
## Environment

 Exports JAAS configuration to consumer JVM properties.

      @write
        header: 'Environment'
        destination: "#{kafka.consumer.conf_dir}/kafka-env.sh"
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
