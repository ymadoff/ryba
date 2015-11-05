
# Kafka Producer Install

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
        destination: "#{kafka.conf_dir}/producer.properties"
        write: for k, v of kafka.producer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @write
        destination: "#{kafka.conf_dir}/tools-log4j.properties"
        write: for k, v of kafka.producer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @then next

## Dependencies

    quote = require 'regexp-quote'
