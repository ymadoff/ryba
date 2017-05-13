
# Druid Historical Wait

    module.exports = header: 'Druid Historical Wait', label_true: 'STOPPED', handler: ->
      options = {}
      options.wait_tcp = for historical in @contexts 'ryba/druid/historical'
        host: historical.config.host
        port: historical.config.ryba.druid.historical.runtime['druid.port']

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp
