
# Shinken Broker Configure

    module.exports = handler: ->
      {shinken} = @config.ryba
      broker = shinken.broker ?= {}
      # Additionnal modules to install
      broker.modules ?= {}
      # WebUI
      webui = broker.modules['webui2'] ?= {}
      webui.version ?= "2.3.2"
      webui.source ?= "https://github.com/shinken-monitoring/mod-webui/archive/#{webui.version}.zip"
      webui.archive ?= "mod-webui-#{webui.version}"
      webui.pip_modules ?= {}
      webui.pip_modules.bottle ?= {}
      webui.pip_modules.bottle.version ?= '0.12.8'
      webui.pip_modules.bottle.url ?= 'https://pypi.python.org/packages/source/b/bottle/bottle-0.12.8.tar.gz'
      webui.pip_modules.bottle.md5 ?= '13132c0a8f607bf860810a6ee9064c5b'
      webui.pip_modules.pymongo ?= {}
      webui.pip_modules.pymongo.version ?= '3.0.3'
      webui.pip_modules.pymongo.url ?= 'https://pypi.python.org/packages/source/p/pymongo/pymongo-3.0.3.tar.gz'
      webui.pip_modules.pymongo.md5 ?= '0425d99c2a453144b9c95cb37dbc46e9'
      webui.pip_modules.importlib ?= {}
      webui.pip_modules.importlib.version ?= '1.0.3'
      webui.pip_modules.importlib.url ?= 'https://pypi.python.org/packages/0e/9c/daad476c540c4c36e7b35cf367331f0acf10d09d112cc5083c3e16a77347/importlib-1.0.3.tar.gz'
      webui.pip_modules.importlib.md5 ?= '3ddefaed1eea78525b9bd4ccf194881d'
      webui.pip_modules['alignak-backend-client'] ?= {}
      webui.pip_modules['alignak-backend-client'].version ?= '0.3.0'
      webui.pip_modules['alignak-backend-client'].archive ?= 'alignak_backend_client-0.3.0'
      webui.pip_modules['alignak-backend-client'].url ?= 'https://pypi.python.org/packages/75/71/9794e301f803e5de6ab07e916a28b9218d2e1f6b46d4e8c1078f29b72d7b/alignak_backend_client-0.3.0.tar.gz'
      webui.pip_modules['alignak-backend-client'].md5 ?= 'ae5ff7cb631a9b08451acc7629934db6'
      webui.pip_modules.passlib ?= {}
      webui.pip_modules.passlib.version ?= '1.6.5'
      webui.pip_modules.passlib.url ?= 'https://pypi.python.org/packages/1e/59/d1a50836b29c87a1bde9442e1846aa11e1548491cbee719e51b45a623e75/passlib-1.6.5.tar.gz'
      webui.pip_modules.passlib.md5 ?= 'd2edd6c42cde136a538b48d90a06ad67'
      v.archive ?= "#{k}-#{v.version}" for k, v of webui.pip_modules
      webui.modules ?= {}
      webui.config ?= {}
      webui.config.host ?= '0.0.0.0'
      webui.config.port ?= '7767'
      webui.config.auth_secret ?= 'rybashinken123'
      webui.config.htpasswd_file ?= '/etc/shinken/htpasswd.users'
      uigraphite = webui.modules['ui-graphite'] ?= {}
      uigraphite.type ?= 'graphite-webui'
      uigraphite.version ?= "2.1.2"
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
      logs.version ?= '1.2.0'
      logs.config ?= {}
      logs.config.services_filter ?= 'bi:>0'
      # Graphite
      graphite = broker.modules['graphite2'] ?= {}
      graphite.version ?= '2.1.4'
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
      logstore.config_file ?= 'logstore_null.cfg'
      ## Auto discovery
      
      configmod = (name, mod) =>
        if mod.version?
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.zip"
          mod.archive ?= "mod-#{name}-#{mod.version}"
          mod.config_file ?= "#{name}.cfg"
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
