
# Spark Livy Server Wait

Wait for the Livy Server.

    module.exports = header: 'Spark Livy ServerWait', timeout: -1, label_true: 'READY', handler: ->
      sls_ctxs = @contexts modules: 'ryba/spark/livy_server'

      for sls_ctx in sls_ctxs
        @wait_connect
          host: sls_ctx.config.host
          port: sls_ctx.config.ryba.spark.livy.conf['livy.server.port']
