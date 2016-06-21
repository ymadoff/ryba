
# Hadoop Yarn ResourceManager Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'Spark History Server Wait', timeout: -1, label_true: 'READY', handler: ->
      shs_ctxs = @contexts 'ryba/spark/history_server', require('./configure').handler
      for shs_ctx in shs_ctxs
        @wait_connect
          host: shs_ctx.config.host
          port: shs_ctx.config.ryba.spark.history.conf['spark.history.ui.port']
