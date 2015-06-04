
# Kafka Consumer Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/kafka'
    module.exports.push require('./index').configure

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
      .then next

## Dependencies

    quote = require 'regexp-quote'
