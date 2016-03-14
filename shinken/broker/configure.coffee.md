
# Shinken Broker Configure

    module.exports = handler: ->
      {shinken} = @config.ryba
      broker = shinken.broker ?= {}
      # Additionnal modules to install
      broker.modules ?= {}
      # WebUI
      webui = broker.modules['webui2'] ?= {}
      webui.version ?= "2.0.1"
      webui.source ?= "https://github.com/shinken-monitoring/mod-webui/archive/#{webui.version}.zip"
      webui.archive ?= "mod-webui-#{webui.version}"
      webui.modules ?= {}
      webui.config ?= {}
      webui.config.host ?= '0.0.0.0'
      webui.config.port ?= '7767'
      webui.config.auth_secret ?= 'rybashinken123'
      webui.config.htpasswd_file ?= '/etc/shinken/htpasswd.users'
      uigraphite = webui.modules['ui-graphite'] ?= {}
      uigraphite.type ?= 'graphite-webui'
      uigraphite.version ?= "2.1.1"
      uigraphite.source ?= "https://github.com/shinken-monitoring/mod-ui-graphite/archive/#{uigraphite.version}.zip"
      uigraphite.archive ?= "mod-ui-graphite-#{uigraphite.version}"
      uigraphite.config ?= {}
      uigraphite.config.uri ?= 'http://localhost:3080/'
      uigraphite.config.templates_path ?= "#{shinken.user.home}/share/templates/graphite/"
      uigraphite.config.dashboard_view_font ?= '8'
      uigraphite.config.dashboard_view_width ?= '320'
      uigraphite.config.dashboard_view_height ?= '240'
      uigraphite.config.detail_view_font ?= '10'
      uigraphite.config.detail_view_width ?= '786'
      uigraphite.config.detail_view_height ?= '308'
      uigraphite.config.color_warning ?= 'orange'
      uigraphite.config.color_critical ?= 'red'
      uigraphite.config.color_min ?= 'black'
      uigraphite.config.color_max ?= 'blue'
      # Logs
      logs =  broker.modules['mongo-logs'] ?= {}
      logs.version ?= '1.1.0'
      logs.config ?= {}
      logs.config.services_filter ?= 'bi:>0'
      # Graphite
      graphite = broker.modules['graphite2'] ?= {}
      graphite.version ?= '2.1.0'
      graphite.source ?= "https://github.com/shinken-monitoring/mod-graphite/archive/#{graphite.version}.zip"
      graphite.archive ?= "mod-graphite-#{graphite.version}"
      graphite.type ?= 'graphite_perfdata'
      # Livestatus
      livestatus = broker.modules['livestatus'] ?= {}
      livestatus.version ?= '1.4.1'
      livestatus.modules ?= {}
      livestatus.config ?= {}
      livestatus.config.host ?= '*'
      livestatus.config.port ?= '50000'
      logstore = livestatus.modules['logstore-null'] ?= {}
      logstore.version ?= '1.4.1'
      logstore.type ?= 'logstore_null'
      ## Auto discovery
      configmod = (name, mod) =>
        if mod.version?
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.zip"
          mod.archive ?= "mod-#{name}-#{mod.version}"
        mod.modules ?= {}
        mod.config ?= {}
        mod.config.modules = [mod.config.modules] if typeof mod.config.modules is 'string'
        mod.config.modules ?= Object.keys mod.modules
        for subname, submod of mod.modules then configmod subname, submod
      for name, mod of broker.modules then configmod name, mod
      # CONFIG
      broker.config ?= {}
      broker.config.port ?= 7772
      broker.config.spare ?= '0'
      broker.config.realm ?= 'All'
      broker.config.manage_arbiters ?= if @hosts_with_module('ryba/shinken/broker').indexOf(@config.host) is 0 then '1' else '0'
      broker.config.modules = [broker.config.modules] if typeof broker.config.modules is 'string'
      broker.config.modules ?= Object.keys broker.modules
      broker.config.use_ssl ?= shinken.config.use_ssl
      broker.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
