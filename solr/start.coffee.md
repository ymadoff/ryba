
# Solr Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

    module.exports.push name: 'Solr # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'solr'
        action: 'start'
        if_exists: '/etc/init.d/solr'
      , next
