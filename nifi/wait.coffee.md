
# NiFi Wait

    module.exports = header: 'NiFi Wait', label_true: 'CHECKED', handler: ->
      options = {}
      options.webui = for nifi_ctx in @contexts 'ryba/nifi'
        {nifi} = nifi_ctx.config.ryba
        protocol = if nifi.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'
        webui = nifi.config.properties["nifi.web.#{protocol}.port"]
        host:  nifi_ctx.config.host
        port: webui

## Web UI Port

      @connection.wait
        header: 'Web UI'
        servers: options.webui
