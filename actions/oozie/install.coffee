
path = require 'path'
mecano = require 'mecano'

module.exports = (ctx, next) ->
  @name 'Oozie # ExtJS'
  @timeout 2*60*1000
  {extjs_url, destination} = ctx.config.oozie
  proxy = if ctx.config.proxy then "--proxy #{ctx.config.proxy.host}:#{ctx.config.proxy.port}" else ''
  # Download archive folder
  ctx.execute
    cmd: "curl -L #{proxy} #{extjs_url} -o /tmp/#{path.basename extjs_url}"
  , (err, executed) ->
    return next err if err
    # Decompress
    ctx.execute
      cmd: "cd /tmp && unzip /tmp/#{path.basename extjs_url}"
    , (err, executed) ->
      return next err if err
      # Move to final destination
      tempdestination = "/tmp/#{path.basename extjs_url, '.zip'}"
      ctx.execute
        cmd: "rm -rf #{destination} && mv #{tempdestination} #{destination}"
      , (err, executed) ->
          next err, ctx.OK