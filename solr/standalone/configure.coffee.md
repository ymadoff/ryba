

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

    module.exports = handler: ->
      solr = @config.ryba.solr ?= {}
      solr.version ?= '5.5.0'
      solr.install_dir ?= "/usr/solr/#{solr.version}"
      solr.var_dir ?= '/var/solr'
      solr.log_dir ?= '/var/log/solr'
      solr.conf_dir ?= '/etc/solr/conf'
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

      solr.source ?= "http://wwwftp.ciril.fr/pub/apache/lucene/solr/#{solr.version}/solr-#{solr.version}.tgz"
      solr.mode ?= 'cloud'
      solr.port ?= 8983
      # Kerberos
      solr.principal ?= "solr/#{@config.host}@#{@config.ryba.realm}"
      solr.keytab ?= '/etc/security/keytabs/solr.service.keytab'
      if solr.mode is 'cloud'
        zk_hosts = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
        zk_connect = zk_hosts.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
        solr.zkhosts = "#{zk_connect}/solr"

      
## Dependencies

    path = require 'path'
