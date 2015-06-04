
# Kafka Broker Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

## Check TCP

Make sure the broker is listening. The default port is "9092".

    module.exports.push name: 'Kafka Broker # Check TCP', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{kafka.broker['port']}"
      .then next
