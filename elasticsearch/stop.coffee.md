
# ElasticSearch Stop

This commands stops ElasticSearch service.

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

    module.exports.push name: 'ES # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'elasticsearch'
        action: 'stop'
      , next
