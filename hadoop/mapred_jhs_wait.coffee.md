
# MapRed JobHistoryServer Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

    module.exports.push name: 'Hadoop MapRed JHS # Wait', label_true: 'READY', callback: (ctx, next) ->
      jhs_ctxs = ctx.contexts 'ryba/hadoop/mapred_jhs'
      if jhs_ctxs.length is 0 then return next() else jhs_ctx = jhs_ctxs[0]
      [_, port] = jhs_ctx.config.ryba.mapred_site['mapreduce.jobhistory.address'].split ':'
      ctx.waitIsOpen jhs_ctx.config.host, port, next
