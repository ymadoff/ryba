
# Phoenix QueryServer Wait

    module.exports = header: 'Phoenix QueryServer Wait', label_true: 'CHECKED', handler: ->
      {queryserver} = @config.ryba.phoenix

## Check TCP

      @connection.wait
        host:  @config.host
        port: queryserver.site['phoenix.queryserver.http.port']
