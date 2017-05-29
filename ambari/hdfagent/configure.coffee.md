.config
# Ambari Agent Configuration

    module.exports = ->
      [srv_ctx] = @contexts 'ryba/ambari/hdfserver'
      @config.ryba ?= {}
      ambari_server = srv_ctx.config.ryba.ambari_hdfserver
      options = @config.ryba.ambari_hdfagent ?= {}

## Environnment

      options.sudo ?= false
      options.conf_dir ?= '/etc/ambari-agent/conf'
      options.repo ?= ambari_server.repo

## Identities

      options.group ?= ambari_server.group
      options.hadoop_group ?= ambari_server.hadoop_group
      options.user ?= ambari_server.user

## Configuration

      options.config ?= {}
      options.config.server ?= {}
      options.config.server['hostname'] ?= "#{srv_ctx.config.host}"
      options.config.server['url_port'] = ambari_server.config['server.url_port']
      options.config.server['secured_url_port'] = ambari_server.config['server.secured_url_port']
      options.config.agent ?= {}
      options.config.agent['hostname_script'] ?= "#{options.conf_dir}/hostname.sh"
