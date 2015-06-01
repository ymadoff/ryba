
# Nagios Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'Nagios # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'nagios'
      .then next
