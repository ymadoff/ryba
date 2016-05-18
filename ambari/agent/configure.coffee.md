    
    
    module.exports = handler: ->
      [srv_ctx] = @contexts 'ryba/ambari/server', require('../server').configure
      ambari_agent = @config.ryba.ambari_agent ?= {}
      ambari_agent.conf_dir ?= '/etc/ambari-agent/conf'
      ambari_agent.ini ?= {}
      ambari_agent.ini.server ?= {}
      ambari_agent.ini.server['hostname'] ?= "#{srv_ctx.config.host}"
      ambari_agent.ini.server['url_port'] ?= "8440"
      ambari_agent.ini.server['secured_url_port'] ?= "8441"
