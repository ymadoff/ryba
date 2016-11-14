
# Cloudera Manager Agent Configuration

Example:

```json
{ "ryba": { "cloudera_manager": { "agent":
    "conf_dir": "/etc/cloudera-scm-agent",
    "ini": {
      "server": {
        "hostname": 'utility1.cluster',
        "port": '7182'
      }
    }
} } }
```

    module.exports = ->
      cdm_ctxs = @contexts 'ryba/cloudera-manager/server'
      return Error 'Need at least one cloudera manager server' unless cdm_ctxs.length > 0
      cloudera_manager = @config.ryba.cloudera_manager ?= {}
      cloudera_manager.agent ?= {}
      cloudera_manager.agent.conf_dir ?= '/etc/cloudera-scm-agent'
      cloudera_manager.agent.ini ?= {}
      cloudera_manager.agent.ini.server ?= {}
      cloudera_manager.agent.ini.server['hostname'] ?= "#{cdm_ctxs[0].config.host}"
      cloudera_manager.agent.ini.server['url_port'] ?= "#{cdm_ctxs[0].config.ryba.cloudera_manager.server.admin_port}"
