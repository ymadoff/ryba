
# Titan

Titan is a distributed graph database. It is an hadoop-friendly implementation of [TinkerPop]
[Blueprints]. Therefore it also use ThinkerPop REPL [Gremlin], and Front server [Rexster]

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.configure = (ctx) ->
      return if ctx.titan_configured
      ctx.titan_configured = true

      titan = ctx.config.ryba.titan ?= {}
      # Layout
      titan.install_dir ?= '/opt/titan/'
      titan.home ?= path.join titan.install_dir, 'current'
      titan.version ?= '0.5.4'

Titan 0.5.x can be found [here](http://s3.thinkaurelius.com/downloads/titan/titan-#{titan.version}-hadoop2.zip)

      titan.source ?= "http://s3.thinkaurelius.com/downloads/titan/titan-#{titan.version}-hadoop2.zip"
      # Configuration
      titan.config ?= {}

Storage Backend

      titan.config['storage.backend'] ?= 'hbase'
      if titan.config['storage.backend'] is 'hbase'
        require('../hbase/client').configure ctx
        zk_hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
        titan.config['storage.hostname'] ?= zk_hosts.join ','
        titan.config['storage.hbase.table'] ?= 'titan'
        titan.config['storage.hbase.short-cf-names'] ?= true

Indexation backend (mandatory even if it should not be)

      titan.config['index.search.backend'] ?= 'elasticsearch'

      if titan.config['index.search.backend'] is 'elasticsearch'
        es_ctxs = ctx.contexts 'ryba/elasticsearch', require('../elasticsearch').configure
        titan.config['index.search.elasticsearch.client-only'] ?= true
        titan.config['index.search.elasticsearch.interface'] ?= 'NODE'
        titan.config['index.search.elasticsearch.ext.node.data'] ?= true
        titan.config['index.search.elasticsearch.ext.node.client'] ?= false
        titan.config['index.search.elasticsearch.ext.node.local'] ?= true

      # else if titan.config['index.search.backend'] is 'solr'
      #   zk_ctxs = ctx.contexts 'ryba/zookeeper/server', require('../zookeeper/server').configure
      #   solr_ctxs = ctx.contexts 'ryba/solr', require('../solr').configure
      #   titan.config['index.seach.solr.mode'] = solr_ctxs[0].config.ryba.solr.mode
      #   titan.config['index.search.solr.zookeeper-url'] ?= "#{zk_ctxs[0].config.host}:#{zk_ctxs[0].config.ryba.zookeeper.port}"

Cache configuration

      titan.config['cache.db-cache'] ?= true
      titan.config['cache.db-cache-clean-wait'] ?= 20
      titan.config['cache.db-cache-time'] ?= 180000
      titan.config['cache.db-cache-size'] ?= 0.5

    module.exports.push commands: 'backup', modules: 'ryba/titan/backup'

    module.exports.push commands: 'install', modules: 'ryba/titan/install'

    module.exports.push commands: 'check', modules: 'ryba/titan/check'

## Resources

[TinkerPop]: http://www.tinkerpop.com/
[Blueprints]: https://github.com/tinkerpop/blueprints/wiki
[Gremlin]: https://github.com/tinkerpop/gremlin/wiki
[Rexster]: https://github.com/tinkerpop/rexster/wiki

## Module Dependencies

    path = require 'path'
