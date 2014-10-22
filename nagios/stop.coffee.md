
# Nagios Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./install').configure

    module.exports.push name: 'Nagios # Stop', callback: (ctx, next) ->
      ctx.service
        srv_name: 'nagios'
        action: 'stop'
      , next
