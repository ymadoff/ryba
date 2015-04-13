
# Kafka Consumer Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/kafka/lib/commons'
    module.exports.push require('./index').configure

## Configure

Update the file "server.properties" with the properties defined by the
"ryba.kafka.server" configuration.

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
      , next

## Dependencies

    quote = require 'regexp-quote'





