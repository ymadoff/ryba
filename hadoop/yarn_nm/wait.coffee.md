
# Hadoop Yarn NodeManagers Wait

Wait for the NodeManagers HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'YARN NM Wait', timeout: -1, label_true: 'READY', handler:  ->
      options = {}
      options.wait_tcp = for nm_ctx in @contexts 'ryba/hadoop/yarn_nm'
        port = nm_ctx.config.ryba.yarn.site['yarn.nodemanager.address'].split(':')[1]
        host: nm_ctx.config.host, port: port
      options.wait_tcp_localiser = for nm_ctx in @contexts 'ryba/hadoop/yarn_nm'
        port = nm_ctx.config.ryba.yarn.site['yarn.nodemanager.localizer.address'].split(':')[1]
        host: nm_ctx.config.host, port: port
      options.wait_webapp = for nm_ctx in @contexts 'ryba/hadoop/yarn_nm'
        protocol = if nm_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
        port = nm_ctx.config.ryba.yarn.site["yarn.nodemanager.webapp.#{protocol}address"].split(':')[1]
        host: nm_ctx.config.host, port: port

## TCP Addresss

      @connection.wait
        header: 'TCP'
        quorum: 1
        servers: options.wait_tcp 

## TCP Localizer Address

      @connection.wait
        header: 'TCP Localizer'
        quorum: 1
        servers: options.wait_tcp_localiser

## Webapp HTTP Adress

      @connection.wait
        header: 'HTTP Webapp'
        quorum: 1
        servers: options.wait_webapp
