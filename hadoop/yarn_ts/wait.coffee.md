
# YARN Timeline Server Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'YARN ATS Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_webapp = for ats_ctx in @contexts 'ryba/hadoop/yarn_ts'
        {yarn} = ats_ctx.config.ryba
        protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
        [host, port] = yarn.site["yarn.timeline-service.webapp.#{protocol}address"].split ':'
        host: host, port: port

## Webapp Address

      @connection.wait
        header: 'Webapp'
        servers: options.wait_webapp
