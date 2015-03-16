
# MapReduce JobHistoryServer Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

    module.exports.push name: 'MapReduce JHS # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      jhs_ctxs = ctx.contexts 'ryba/hadoop/mapred_jhs', require('./mapred_jhs').configure
      if jhs_ctxs.length is 0 then return next() else jhs_ctx = jhs_ctxs[0]
      [_, port] = jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.address'].split ':'
      ctx.waitIsOpen jhs_ctx.config.host, port, next
