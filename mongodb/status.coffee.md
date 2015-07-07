
# MongoDB Server Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'


    module.exports.push name: 'MongoDB Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service mongod status'
        code_skipped: 3
      .then next
