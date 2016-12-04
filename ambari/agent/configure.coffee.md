

    module.exports = ->
      [srv_ctx] = @contexts 'ryba/ambari/server'
      ambari_agent = @config.ryba.ambari_agent ?= {}
      ambari_agent.sudo ?= false
      ambari_agent.conf_dir ?= '/etc/ambari-agent/conf'
      ambari_agent.ini ?= {}
      ambari_agent.ini.server ?= {}
      ambari_agent.ini.server['hostname'] ?= "#{srv_ctx.config.host}"
      ambari_agent.ini.server['url_port'] ?= "8440"
      ambari_agent.ini.server['secured_url_port'] ?= "8441"
      ambari_agent.ini.agent ?= {}
      ambari_agent.ini.agent['hostname_script'] ?= "#{ambari_agent.conf_dir}/hostname.sh"
