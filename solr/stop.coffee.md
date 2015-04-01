
# Solr Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

    module.exports.push name: 'Solr # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'solr'
        action: 'stop'
        if_exists: '/etc/init.d/solr'
      , next
