
# ElasticSearch Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

    module.exports.push name: 'ES # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'elasticsearch'
      .then next
