
# Phoenix QueryServer Wait

    module.exports = header: 'Phoenix QueryServer Wait', label_true: 'CHECKED', handler: ->
      [qs_ctx] = @contexts 'ryba/phoenix/queryserver'
      options = {}
      options.http = 
        host: qs_ctx.config.host
        port: qs_ctx.config.ryba.phoenix.queryserver.site['phoenix.queryserver.http.port']

## Check TCP

      @connection.wait servers: options.http
