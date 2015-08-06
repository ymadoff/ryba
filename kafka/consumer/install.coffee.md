
# Kafka Consumer Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require('./index').configure

## Package

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

    module.exports.push name: 'Kafka Consumer # Package', handler: (ctx, next) ->
      ctx
      .service
        name: 'kafka'
      .hdp_select
        name: 'kafka-broker'
      .then next

## Configure

Update the file "consumer.properties" with the properties defined by the
"ryba.kafka.consumer" configuration.

    module.exports.push name: 'Kafka Consumer # Configure', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.write
        destination: "#{kafka.conf_dir}/consumer.properties"
        write: for k, v of kafka.consumer
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      ctx.write
        destination: "#{kafka.conf_dir}/tools-log4j.properties"
        write: for k, v of kafka.consumer.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      .then next

## Dependencies

    quote = require 'regexp-quote'
