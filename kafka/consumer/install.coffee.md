
# Kafka Consumer Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/lib/hdp_select'

## Users & Groups

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

    module.exports.push header: 'Kafka Consumer # Users & Groups', handler: ->
      {kafka} = @config.ryba
      @group kafka.group
      @user kafka.user

## Package

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

    module.exports.push header: 'Kafka Consumer # Package', handler: ->
      @service
        name: 'kafka'
      @hdp_select
        name: 'kafka-broker'

## Configure

Update the file "consumer.properties" with the properties defined by the
"ryba.kafka.consumer" configuration.

    module.exports.push header: 'Kafka Consumer # Configure', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.conf_dir}/consumer.properties"
        write: for k, v of kafka.consumer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @write
        destination: "#{kafka.conf_dir}/tools-log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Dependencies

    quote = require 'regexp-quote'
