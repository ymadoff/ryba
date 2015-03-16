
# Nagios Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push skip: true, name: 'Nagios # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'nagios'
        action: 'start'
      , next
