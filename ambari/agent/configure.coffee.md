.config
# Ambari Agent Configuration

    module.exports = ->
      [srv_ctx] = @contexts 'ryba/ambari/server'
      @config.ryba ?= {}
      ambari_server = srv_ctx.config.ryba.ambari_server
      ambari_agent = @config.ryba.ambari_agent ?= {}

## Environnment

      ambari_agent.sudo ?= false
      ambari_agent.conf_dir ?= '/etc/ambari-agent/conf'
      ambari_agent.repo ?= ambari_server.repo

## Identities

      ambari_agent.group ?= ambari_server.group
      ambari_agent.hadoop_group ?= ambari_server.hadoop_group
      ambari_agent.user ?= ambari_server.user

## Configuration

      ambari_agent.config ?= {}
      ambari_agent.config.server ?= {}
      ambari_agent.config.server['hostname'] ?= "#{srv_ctx.config.host}"
      ambari_agent.config.server['url_port'] = ambari_server.config['server.url_port']
      ambari_agent.config.server['secured_url_port'] = ambari_server.config['server.secured_url_port']
      ambari_agent.config.agent ?= {}
      ambari_agent.config.agent['hostname_script'] ?= "#{ambari_agent.conf_dir}/hostname.sh"
