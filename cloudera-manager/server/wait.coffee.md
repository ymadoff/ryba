
# Cloudera ManagerServer Wait

    module.exports = header: 'Cloudera Manager Server Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for cdm_ctx in @contexts 'ryba/cloudera-manager/server'
          [
            host: cdm_ctx.config.host
            port: cdm_ctx.config.ryba.cloudera_manager.server.admin_port
          ,
            host: cdm_ctx.config.host
            port: cdm_ctx.config.ryba.cloudera_manager.server.ui_port
        ]
