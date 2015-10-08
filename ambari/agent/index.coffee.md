# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed.
The ambari server must be installed before performing manual registration.


    module.exports = []
     
    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      [srv_ctx] = ctx.contexts 'ryba/ambari/server', require('../server').configure
      ambari_agent = ctx.config.ryba.ambari_agent ?= {}
      ambari_agent.conf_dir ?= '/etc/ambari-agent/conf'
      ambari_agent.ini ?= {}
      ambari_agent.ini.server ?= {}
      ambari_agent.ini.server['hostname'] ?= "#{srv_ctx.config.host}"
      ambari_agent.ini.server['url_port'] ?= "8440"
      ambari_agent.ini.server['secured_url_port'] ?= "8441"

    module.exports.push commands: 'install', modules: [
      'ryba/ambari/agent/install'
      'ryba/ambari/agent/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/ambari/agent/start'

    module.exports.push commands: 'stop', modules: 'ryba/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
