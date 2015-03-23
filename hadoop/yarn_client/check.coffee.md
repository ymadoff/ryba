
# Yarn Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure
    module.exports.push 'ryba/hadoop/yarn_rm/wait'

## Check CLI

    module.exports.push name: 'YARN Client # Check CLI', label_true: 'CHECKED', handler: (ctx, next) ->
      ctx.execute
        cmd: mkcmd.test ctx, 'yarn application -list'
      , next

## Module Dependencies

    mkcmd = require '../../lib/mkcmd'


