
# MongoDB Shard Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'


    module.exports.push name: 'MongoDB Shard # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service mongos status'
        code_skipped: 3
      .then next
