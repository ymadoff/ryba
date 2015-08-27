
# YARN Timeline Server Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'YARN TS # Wait HTTP', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      [ats_ctx] = ctx.contexts modules: 'ryba/hadoop/yarn_ts', require('./index').configure
      return next() unless ats_ctx
      {yarn} = ats_ctx.config.ryba
      protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
      [host, port] = yarn.site["yarn.timeline-service.webapp.#{protocol}address"].split ':'
      ctx.wait_connect
        host: host
        port: port
      .then next