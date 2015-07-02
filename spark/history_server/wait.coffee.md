
# Hadoop Yarn ResourceManager Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Spark History Server # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      shs_ctxs = ctx.contexts modules: 'ryba/spark/history_server', require('./index').configure
      servers = for shs_ctx in shs_ctxs
        host: shs_ctx.config.host
        port: shs_ctx.config.ryba.spark.conf['spark.history.ui.port']
      ctx.waitIsOpen servers , next