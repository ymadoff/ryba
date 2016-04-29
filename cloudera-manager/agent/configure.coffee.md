
# Cloudera Manager Agent Configuration

Example:

```json
cloudera_manager:
  agent:
    conf_dir: '/etc/cloudera-scm-agent/'
    ini:
      server:
        hostname: 'server-hostname'
        port: '7182'
```

    module.exports = handler: ->
      cdm_ctxs = @contexts 'ryba/cloudera-manager/server', [require('../../commons/db_admin').handler, require('../server/configure').handler]
      return Error 'Need at least one cloudera manager server' unless cdm_ctxs.length > 0
      cloudera_manager = @config.ryba.cloudera_manager ?= {}
      agent = @config.ryba.cloudera_manager.agent ?= {}
      agent.conf_dir ?= '/etc/cloudera-scm-agent'
      agent.ini ?= {}
      agent.ini.server ?= {}
      agent.ini.server['hostname'] ?= "#{cdm_ctxs[0].config.host}"
      agent.ini.server['url_port'] ?= "#{cdm_ctxs[0].config.ryba.cloudera_manager.server.admin_port}"
