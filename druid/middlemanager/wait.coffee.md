
# Druid MiddleManager Wait

    module.exports = header: 'Druid MiddleManager Wait', label_true: 'STOPPED', handler: ->
      options = {}
      options.wait_tcp = for middlemanager in @contexts 'ryba/druid/middlemanager'
        host: middlemanager.config.host
        port: middlemanager.config.ryba.druid.middlemanager.runtime['druid.port']

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp
