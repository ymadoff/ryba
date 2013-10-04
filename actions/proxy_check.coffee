
proxy = require './proxy'

module.exports = []

module.exports.push 'histi/actions/curl'

module.exports.push (ctx) ->
  proxy.configure ctx

module.exports.push (ctx, next) ->
  {http_proxy} = ctx.config.proxy
  return next() unless http_proxy
  @name 'Proxy Check # Curl'
  ctx.execute
    cmd: "curl --proxy #{http_proxy} http://www.apache.org"
  , (err, executed, stdout) ->
    return next err if err
    return next new Error "Proxy not active" unless  /Welcome to The Apache Software Foundation/.test stdout
    next null, ctx.PASS
