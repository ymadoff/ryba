# Cloudera Manager Agent

[Cloudera Manager Agents][Cloudera-agent-install] on hosts enables the cloudera
manager server to be aware of the hosts where it will deploy the Hadoop stack.
The cloudera manager server must be installed before performing manual registration.
You must have configured yum to use the [cloudera manager repo][Cloudera-manager-repo]
or the [cloudera cdh repo][Cloudera-cdh-repo].


    module.exports = []

## Configuration

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

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      [srv_ctx] = ctx.contexts 'ryba/cloudera-manager/server', require('../server').configure
      {agent} = ctx.config.ryba.cloudera_manager
      agent.conf_dir ?= '/etc/cloudera-scm-agent/'
      agent.ini ?= {}
      agent.ini.server ?= {}
      agent.ini.server['hostname'] ?= "#{srv_ctx.config.host}"
      agent.ini.server['url_port'] ?= "7182"

    module.exports.push commands: 'install', modules: [
      'ryba/cloudera-manager/agent/install'
      'ryba/cloudera-manager/agent/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/cloudera-manager/agent/start'

    module.exports.push commands: 'stop', modules: 'ryba/cloudera-manager/agent/stop'

[Cloudera-agent-install]: http://www.cloudera.com/content/www/en-us/documentation/enterprise/5-2-x/topics/cm_ig_install_path_b.html#cmig_topic_6_6_3_unique_1
[Cloudera-manager-repo]: http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo
[Cloudera-cdh-repo]: http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
