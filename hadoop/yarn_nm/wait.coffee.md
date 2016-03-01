
# Hadoop Yarn NodeManagers Wait

Wait for the NodeManagers HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'YARN NM # Wait', timeout: -1, label_true: 'READY', handler:  ->
      @wait_connect
        quorum: true
        servers: for nm_ctx in @contexts 'ryba/hadoop/yarn_nm'
          {yarn} = nm_ctx.config.ryba
          protocol = if nm_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
          port = nm_ctx.config.ryba.yarn.site["yarn.nodemanager.webapp.#{protocol}address"].split(':')[1]
          host: nm_ctx.config.host, port: port
