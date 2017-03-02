# Hortonworks Smartsense Server Wait

Wait for the HST server wait. Check the three ports (two way ssl ports and webui port)

    module.exports = header: 'HST Server Wait', label_true: 'READY', handler: ->
      for srv_ctx in @contexts 'ryba/smartsense/server'
        @connection.wait
          host: srv_ctx.config.host, port: srv_ctx.config.ryba.smartsense.server.ini['server']['port']
        @connection.wait
          host: srv_ctx.config.host, port: srv_ctx.config.ryba.smartsense.server.ini['security']['server.one_way_ssl.port']
        @connection.wait
          host: srv_ctx.config.host, port: srv_ctx.config.ryba.smartsense.server.ini['security']['server.two_way_ssl.port']
