
# Yarn Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./yarn_client').configure

## Check CLI

    module.exports.push name: 'Hadoop Yarn Client # Check CLI', callback: (ctx, next) ->
      ctx.execute
        cmd: mkcmd.test ctx, 'yarn application -list'
      , next

## Module Dependencies

    mkcmd = require '../lib/mkcmd'


