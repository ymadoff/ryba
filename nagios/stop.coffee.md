
# Nagios Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./install').configure

    module.exports.push name: 'Nagios # Start', callback: (ctx, next) ->
      ctx.service
        srv_name: 'nagios'
        action: 'stop'
      , (err, stoped) ->
        next err, if stoped then ctx.OK else ctx.PASS