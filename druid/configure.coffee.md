
# Druid Configure

Example:

```json
{
  "ryba": {
    "druid": "version": "0.9.1.1"
  }
}
```

    module.exports  = handler: ->
      [pg_ctx] = @contexts 'masson/commons/postgres/server', require('masson/commons/postgres/server').handler
      [my_ctx] = @contexts 'masson/commons/mysql/server', require('masson/commons/postgres/server').handler
      zoo_ctxs = @contexts 'ryba/zookeeper/server', require('../zookeeper/server/configure').handler
      # Get ZooKeeper Quorum
      zookeeper_quorum = for zoo_ctx in zoo_ctxs then "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
        
      @config.ryba ?= {}
      druid = @config.ryba.druid ?= {}
      # Layout
      druid.dir ?= '/opt/druid'
      druid.conf_dir ?= '/etc/druid/conf'
      druid.log_dir ?= '/var/log/druid'
      druid.pid_dir ?= '/var/run/druid'
      druid.server_opts ?= ''
      druid.server_heap ?= ''
      # User
      druid.user = name: druid.user if typeof druid.user is 'string'
      druid.user ?= {}
      druid.user.name ?= 'druid'
      druid.user.system ?= true
      druid.user.comment ?= 'druid User'
      druid.user.home ?= '/var/lib/druid'
      druid.user.groups ?= ['hadoop']
      # Group
      druid.group = name: druid.group if typeof druid.group is 'string'
      druid.group ?= {}
      druid.group.name ?= 'druid'
      druid.group.system ?= true
      druid.user.gid = druid.group.name
      # Package
      druid.version ?= '0.9.1.1'
      druid.source ?= "http://static.druid.io/artifacts/releases/druid-#{druid.version}-bin.tar.gz"
      # Configuration
      druid.runtime ?= {}
      # Extensions
      # Note, Mysql extension isnt natively supported due to licensing issues
      druid.runtime['druid.extensions.loadList'] ?= '["druid-kafka-eight", "druid-s3-extensions", "druid-histogram", "druid-datasketches", "druid-lookups-cached-global"]' # "mysql-metadata-storage"
      # Logging
      druid.runtime['druid.startup.logging.logProperties'] ?= 'true'
      # Zookeeper
      druid.runtime['druid.zk.service.host'] ?= "#{zookeeper_quorum.join ','}"
      druid.runtime['druid.zk.paths.base'] ?= '/druid'
      # Metadata storage
      if pg_ctx then druid.runtime['druid.metadata.storage.type'] ?= 'postgresql'
      else if my_ctx then druid.runtime['druid.metadata.storage.type'] ?= 'mysql'
      else druid.runtime['druid.metadata.storage.type'] ?= 'derby'
      switch druid.runtime['druid.metadata.storage.type']
        when 'postgresql'
          druid.runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:postgresql://#{pg_ctx.config.host}:#{pg_ctx.config.postgres.server.port}/druid"
          druid.runtime['druid.metadata.storage.connector.host'] ?= "#{pg_ctx.config.host}"
          druid.runtime['druid.metadata.storage.connector.port'] ?= "#{pg_ctx.config.postgres.server.port}"
        when 'mysql'
          druid.runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:mysql://db.example.com:3306/druid"
          druid.runtime['druid.metadata.storage.connector.host'] ?= "#{my_ctx.config.host}"
          druid.runtime['druid.metadata.storage.connector.port'] ?= "#{my_ctx.config.postgres.server.port}"
        when 'derby'
          druid.runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:derby://#{@config.host}:1527/var/druid/metadata.db;create=true"
          druid.runtime['druid.metadata.storage.connector.host'] ?= "#{@config.host}"
          druid.runtime['druid.metadata.storage.connector.port'] ?= '1527'
      druid.runtime['druid.metadata.storage.connector.user'] ?= "#{druid.user.name}"
      druid.runtime['druid.metadata.storage.connector.password'] ?= "diurd123"
      # For MySQL:
      #druid.runtime[druid.metadata.storage.type=mysql
      #druid.runtime[druid.metadata.storage.connector.connectURI=jdbc:mysql://db.example.com:3306/druid
      #druid.runtime[druid.metadata.storage.connector.user=...
      #druid.runtime[druid.metadata.storage.connector.password=...
      # For PostgreSQL (make sure to additionally include the Postgres extension):
      #druid.runtime[druid.metadata.storage.type=postgresql
      #druid.runtime[druid.metadata.storage.connector.connectURI=jdbc:postgresql://db.example.com:5432/druid
      #druid.runtime[druid.metadata.storage.connector.user=...
      #druid.runtime[druid.metadata.storage.connector.password=...
      # Deep storage
      # Extension "druid-hdfs-storage" added to "loadList"
      druid.runtime['druid.storage.type'] ?= 'hdfs'
      druid.runtime['druid.storage.storageDirectory'] ?= '/apps/druid/segments'
      # Indexing service logs
      druid.runtime['druid.indexer.logs.type'] ?= 'hdfs'
      druid.runtime['druid.indexer.logs.directory'] ?= '/apps/druid/indexing-logs'
      # Service discovery
      druid.runtime['druid.selectors.indexing.serviceName'] ?= 'druid/overlord'
      druid.runtime['druid.selectors.coordinator.serviceName'] ?= 'druid/coordinator'
      # Monitoring
      druid.runtime['druid.monitoring.monitors'] ?= '["com.metamx.metrics.JvmMonitor"]'
      druid.runtime['druid.emitter'] ?= 'logging'
      druid.runtime['druid.emitter.logging.logLevel'] ?= 'info'
