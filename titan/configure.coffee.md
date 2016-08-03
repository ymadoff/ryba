
# Titan Configuration

    module.exports = handler: ->
      titan = @config.ryba.titan ?= {}
      # Layout
      titan.install_dir ?= '/opt/titan'
      titan.home ?= path.join titan.install_dir, 'current'
      titan.version ?= '1.0.0'

Titan 1.0.0 can be found [here](http://s3.thinkaurelius.com/downloads/titan/titan-#{titan.version}-hadoop2.zip)

      titan.source ?= "http://s3.thinkaurelius.com/downloads/titan/titan-#{titan.version}-hadoop2.zip"
      # Configuration
      titan.config ?= {}

Storage Backend

      titan.config['storage.backend'] ?= 'hbase'
      if titan.config['storage.backend'] is 'hbase'
        zk_hosts = @contexts('ryba/zookeeper/server').map( (ctx)-> ctx.config.host)
        titan.config['storage.hostname'] ?= zk_hosts.join ','
        titan.config['storage.hbase.table'] ?= 'titan'
        titan.config['storage.hbase.short-cf-names'] ?= true

Indexation backend (mandatory even if it should not be)

      titan.config['index.search.backend'] ?= 'elasticsearch'
      if titan.config['index.search.backend'] is 'elasticsearch'
        es_ctxs = @contexts 'ryba/elasticsearch', require('../elasticsearch/configure').handler
        if es_ctxs.length > 0
          titan.config['index.search.hostname'] ?= es_ctxs[0].config.host
          titan.config['index.search.elasticsearch.client-only'] ?= true
          titan.config['index.search.elasticsearch.cluster-name'] ?= es_ctxs[0].config.ryba.elasticsearch.cluster.name
        unless titan.config['index.search.hostname']? and titan.config['index.search.elasticsearch.cluster-name']?
          throw Error "Cannot autoconfigure elasticsearch. Provide manual config or install elasticsearch"
      else if titan.config['index.search.backend'] is 'solr'
        zk_ctxs = @contexts 'ryba/zookeeper/server', require('../zookeeper/server/configure').handler
        solr_ctxs = @contexts 'ryba/solr', require('../solr/configure').handler
        if solr_ctxs.length > 0
          titan.config['index.seach.solr.mode'] ?= solr_ctxs[0].config.ryba.solr.mode
          titan.config['index.search.solr.zookeeper-url'] ?= "#{zk_ctxs[0].config.host}:#{zk_ctxs[0].config.ryba.zookeeper.port}"
        unless titan.config['index.seach.solr.mode']? and titan.config['index.search.solr.zookeeper-url']?
          throw Error "Cannot autoconfigure solr. Provide manual config or install solr"
      else throw Error "Invalid search.backend '#{titan.config['index.search.backend']}', 'solr' or 'elasticsearch' expected"

Cache configuration

      titan.config['cache.db-cache'] ?= true
      titan.config['cache.db-cache-clean-wait'] ?= 20
      titan.config['cache.db-cache-time'] ?= 180000
      titan.config['cache.db-cache-size'] ?= 0.5

## Dependencies

    path = require 'path'
