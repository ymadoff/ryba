
# WebHCat Status

    lifecycle = require '../lib/lifecycle'

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./webhcat').configure ctx

    module.exports.push name: 'WebHCat # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service hive-webhcat-server status'
        code_skipped: 3
        if_exists: '/etc/init.d/hive-webhcat-server'
      , next

