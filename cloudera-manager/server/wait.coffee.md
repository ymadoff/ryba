
# Cloudera ManagerServer Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'Cloudera Manager Server # Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for cdm_ctx in @contexts 'ryba/cloudera-manager/server', require('./index').configure
          [
            host: cdm_ctx.config.host
            port: cdm_ctx.config.ryba.cloudera_manager.server.admin_port
          ,
            host: cdm_ctx.config.host
            port: cdm_ctx.config.ryba.cloudera_manager.server.ui_port
        ]
