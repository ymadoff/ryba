
# Hortonworks Smartsense Agent Configuration
    
    module.exports = handler: ->
      {java, ryba} = @config
      {hadoop_conf_dir, core_site,realm} = ryba
      {smartsense} = ryba ?= {}
      # User & Group
      [srv_ctx] = @contexts 'ryba/smartsense/server', require('../server/configure').handler
      smartsense.user = srv_ctx.config.ryba.smartsense.user
      smartsense.group = srv_ctx.config.ryba.smartsense.group
      # User
      smartsense.user ?= {}
      smartsense.user = name: smartsense.user if typeof smartsense.user is 'string'
      smartsense.user.name ?= 'smartsense'
      smartsense.user.system ?= true
      smartsense.user.comment ?= 'Hortonworks SmartSense User'
      smartsense.user.home ?= '/var/lib/smartsense'
      smartsense.user.groups ?= 'hadoop'
      # Group
      smartsense.group ?= {}
      smartsense.group = name: smartsense.group if typeof smartsense.group is 'string'
      smartsense.group.name ?= 'smartsense'
      smartsense.group.system ?= true
      smartsense.user.gid ?= smartsense.group.name
      # Source
      smartsense.source ?= "#{__dirname}/../resources/smartsense-hst-1.3.0.0-1.x86_64.rpm"
      agent = smartsense.agent ?= {}
      # Configuration
      agent.conf_dir ?= '/etc/hst/conf'
      agent.source ?= "#{__dirname}/../resources/smartsense-hst-1.3.0.0-1.x86_64.rpm"
      agent.tmp_dir ?= '/tmp'
      agent.pid_dir ?= '/var/run/hst'
      agent.log_dir ?= '/var/log/hst'
      agent.server_host ?= srv_ctx.config.host
      agent.ini ?= {}
      agent.ini['server'] ?= {}
      agent.ini['server']['url_port'] ?= srv_ctx.config.ryba.smartsense.server.ini['security']['server.one_way_ssl.port']
      agent.ini['server']['secured_url_port'] ?= srv_ctx.config.ryba.smartsense.server.ini['security']['server.two_way_ssl.port']
      agent.ini['server']['ssl_enabled'] ?= srv_ctx.config.ryba.smartsense.server.ini['security']['ssl_enabled']
      # note: enabline auto-apply lead to hst-agent.ini file to be change every time server's conf changes
      # we do not want this behaviour because we manage configuration with ryba
      agent.ini['management'] ?= {}
      agent.ini['management']['patch.auto.apply.enabled'] ?= false
