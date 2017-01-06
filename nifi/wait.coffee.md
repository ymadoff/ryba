
# NiFi Wait

    module.exports = header: 'NiFi Wait', label_true: 'CHECKED', handler: ->
      {nifi} = @config.ryba
      protocol = if nifi.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'
      webui = nifi.config.properties["nifi.web.#{protocol}.port"]

## Check TCP

      @connection.wait
        host:  @config.host
        port: webui
