
# NiFi Manager Wait

    module.exports = header: 'NiFI Manager Wait', label_true: 'CHECKED', handler: ->
      [m_ctx] = @contexts 'ryba/nifi/manager'
      protocol = if m_ctx.config.ryba.nifi.manager.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'
      webui = m_ctx.config.ryba.nifi.manager.config.properties["nifi.web.#{protocol}.port"]
      
## Check TCP

Check if all Manager's port are opened
- Webui port
- broadcast port (port used to communicate with nodes)
- admin port (port used by node to authenticate)

      @wait_connect
        host:  m_ctx.config.host
        port: webui
      @wait_connect
        host: m_ctx.config.host
        port: m_ctx.config.ryba.nifi.manager.config.properties['nifi.cluster.manager.protocol.port']
      @wait_connect
        host: m_ctx.config.host
        port: m_ctx.config.ryba.nifi.manager.config.authority_providers.ncm_port
