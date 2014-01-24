
module.exports = []
module.exports.push 'histi/actions/curl'

module.exports.push (ctx) ->
  require('./yum').configure ctx

module.exports.push name: 'YUM # Epel', timeout: 100000, callback: (ctx, next) ->
  {epel, epel_url} = ctx.config.yum
  return next() unless epel
  ctx.execute
    cmd: "rpm -Uvh #{epel_url}"
    code_skipped: 1
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS
