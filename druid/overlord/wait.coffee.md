
# Druid Overlord Wait

    module.exports = header: 'Druid Overlord Wait', label_true: 'STOPPED', handler: ->
      options = {}
      options.wait_tcp = for overlord in @contexts 'ryba/druid/overlord'
        host: overlord.config.host
        port: overlord.config.ryba.druid.overlord.runtime['druid.port']

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp
