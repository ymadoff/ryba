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
      ambari_agent.config ?= {}
      ambari_agent.config.server ?= {}
      ambari_agent.config.server['hostname'] ?= "#{srv_ctx.config.host}"
      ambari_agent.config.server['url_port'] ?= "8440"
      ambari_agent.config.server['secured_url_port'] ?= "8441"
 
    module.exports.push commands: 'install', modules: [
      'ryba/ambari/agent/install'
    ]

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts