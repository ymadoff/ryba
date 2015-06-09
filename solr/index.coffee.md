
# Solr
[Solr](http://lucene.apache.org/solr/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Configure

Example:

```json
{
  "ryba": {
    "solr": {
      var_dir: "/var/solr",
      install_dir: "/opt",
      log_dir: "/var/log/solr"
      mode: 'cloud'
    }
  }
}
```

    module.exports.configure = (ctx) ->
      solr = ctx.config.ryba.solr ?= {}
      solr.install_dir ?= '/opt'
      solr.var_dir ?= '/var/solr'
      solr.log_dir ?= '/var/log/solr'
      solr.user ?= {}
      solr.user = name: solr.user if typeof solr.user is 'string'
      solr.user.name ?= 'solr'
      solr.user.home ?= "#{path.join solr.var_dir, 'data'}"
      solr.user.system ?= true
      solr.user.comment ?= 'Solr User'
      # Group
      solr.group ?= {}
      solr.group = name: solr.group if typeof solr.group is 'string'
      solr.group.name ?= 'solr'
      solr.group.system ?= true
      solr.user.gid ?= solr.group.name
      # Layout
      solr.version ?= '5.0.0'
      solr.mode ?= 'cloud'
      solr.port ?= 8983
      # Kerberos
      solr.principal ?= "solr/#{ctx.config.host}@#{ctx.config.ryba.realm}"
      solr.keytab ?= '/etc/security/keytabs/solr.service.keytab'
      if solr.mode is 'cloud'
        require('../zookeeper/client').configure ctx
        {zookeeper} = ctx.config.ryba
        solr.zkhosts = ctx.hosts_with_module('ryba/zookeeper/server').join ":#{zookeeper.port},"
        solr.zkhosts = "#{solr.zkhosts}:#{zookeeper.port}/solr"

Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/)

      solr.source ?= "http://wwwftp.ciril.fr/pub/apache/lucene/solr/#{solr.version}/solr-#{solr.version}.tgz"

    module.exports.push commands: 'install', modules: [
      'ryba/solr/install',
      'ryba/solr/start',
      'ryba/solr/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/solr/start'

    module.exports.push commands: 'check', modules: 'ryba/solr/check'

    module.exports.push commands: 'status', modules: 'ryba/solr/status'

    module.exports.push commands: 'stop', modules: 'ryba/solr/stop'

## Dependencies

    path = require 'path'
