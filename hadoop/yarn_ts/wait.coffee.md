
# YARN Timeline Server Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'YARN TS # Wait HTTP', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for ats_ctx in @contexts 'ryba/hadoop/yarn_ts'
          {yarn} = ats_ctx.config.ryba
          protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
          [host, port] = yarn.site["yarn.timeline-service.webapp.#{protocol}address"].split ':'
          host: host, port: port
          
