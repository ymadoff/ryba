
# Kafka Producer Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hdp_select'

## Package

Install the Kafka producer package and set it to the latest version. Note, we
select the "kafka-broker" HDP directory. There is no "kafka-producer"
directories.

    module.exports.push name: 'Kafka Producer # Package', handler: ->
      @service
        name: 'kafka'
      @hdp_select
        name: 'kafka-broker'

## Configure

Update the file "server.properties" with the properties defined by the
"ryba.kafka.server" configuration.

    module.exports.push name: 'Kafka Producer # Configure', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.conf_dir}/producer.properties"
        write: for k, v of kafka.producer
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

## Dependencies

    quote = require 'regexp-quote'
