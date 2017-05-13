
# Hadoop Yarn ResourceManager Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'Spark History Server Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_ui = for shs_ctx in @contexts 'ryba/spark/history_server'
        host: shs_ctx.config.host
        port: shs_ctx.config.ryba.spark.history.conf['spark.history.ui.port']

## UI Port

      @connection.wait
        header: 'UI'
        servers: options.wait_ui
