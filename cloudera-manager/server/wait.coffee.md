
# Cloudera ManagerServer Wait

    module.exports = header: 'Cloudera Manager Server Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_admin = for cdm_ctx in @contexts 'ryba/cloudera-manager/server'
        host: cdm_ctx.config.host
        port: cdm_ctx.config.ryba.cloudera_manager.server.admin_port
      options.wait_ui = for cdm_ctx in @contexts 'ryba/cloudera-manager/server'
        host: cdm_ctx.config.host
        port: cdm_ctx.config.ryba.cloudera_manager.server.ui_port

## Admin Port

      @connection.wait
        header: 'Admin'
        servers: options.wait_admin

## UI Port

      @connection.wait
        header: 'UI'
        servers: options.wait_ui
