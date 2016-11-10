
# Druid Configure

Example:

```json
{
  "ryba": {
    "druid": "version": "0.9.1.1"
  }
}
```

    module.exports = ->
      [pg_ctx] = @contexts 'masson/commons/postgres/server'
      [my_ctx] = @contexts 'masson/commons/mysql/server'
      zoo_ctxs = @contexts 'ryba/zookeeper/server'
      [hadoop_ctx] = @contexts 'ryba/hadoop/core'
      # Get ZooKeeper Quorum
      zookeeper_quorum = for zoo_ctx in zoo_ctxs then "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      @config.ryba ?= {}
      {realm} = @config.ryba
      druid = @config.ryba.druid ?= {}
      # Layout
      druid.dir ?= '/opt/druid'
      druid.conf_dir ?= '/etc/druid/conf'
      druid.log_dir ?= '/var/log/druid'
      druid.pid_dir ?= '/var/run/druid'
      druid.server_opts ?= ''
      druid.server_heap ?= ''
      druid.hadoop_conf_dir ?= hadoop_ctx.config.ryba.hadoop_conf_dir
      # User
      druid.user = name: druid.user if typeof druid.user is 'string'
      druid.user ?= {}
      druid.user.name ?= 'druid'
      druid.user.system ?= true
      druid.user.comment ?= 'Druid User'
      druid.user.home ?= "/var/lib/#{druid.user.name}"
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
      # Kerberos
      druid.krb5_admin ?= {}
      druid.krb5_admin.principal ?= "druid@#{realm}"
      druid.krb5_admin.password ?= "druid123"
      druid.krb5_service ?= {}
      druid.krb5_service.principal ?= "druid/#{@config.host}@#{realm}"
      druid.krb5_service.keytab ?= "#{druid.dir}/conf/druid/_common/druid.keytab"
      # Configuration
      druid.common_runtime ?= {}
      # Extensions
      # Note, Mysql extension isnt natively supported due to licensing issues
      # "druid-s3-extensions", 
      druid.common_runtime['druid.extensions.loadList'] ?= '["druid-kafka-eight", "druid-histogram", "druid-datasketches", "druid-lookups-cached-global", "postgresql-metadata-storage", "druid-hdfs-storage"]' # "mysql-metadata-storage"
      # Logging
      druid.common_runtime['druid.startup.logging.logProperties'] ?= 'true'
      # Zookeeper
      druid.common_runtime['druid.zk.service.host'] ?= "#{zookeeper_quorum.join ','}"
      druid.common_runtime['druid.zk.paths.base'] ?= '/druid'
      # Metadata storage
      druid.db ?= {}
      # require('../commons/db_admin').handler.call @
      if pg_ctx then druid.db.engine ?= 'postgres'
      else if my_ctx then druid.db.engine ?= 'mysql'
      else druid.db.engine ?= 'derby'
      druid.db[k] ?= v for k, v of @config.ryba.db_admin[druid.db.engine]
      druid.db.database ?= 'druid'
      druid.db.username ?= 'druid'
      druid.db.password ?= 'druid123'
      switch druid.db.engine
        when 'postgres'
          druid.common_runtime['druid.metadata.storage.type'] ?= 'postgresql'
          druid.common_runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:postgresql://#{druid.db.host}:#{druid.db.port}/#{druid.db.database}"
          druid.common_runtime['druid.metadata.storage.connector.host'] ?= "#{druid.db.host}"
          druid.common_runtime['druid.metadata.storage.connector.port'] ?= "#{druid.db.port}"
        when 'mysql'
          druid.common_runtime['druid.metadata.storage.type'] ?= 'mysql'
          druid.common_runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:mysql://#{druid.db.host}:#{druid.db.port}/#{druid.db.database}"
          druid.common_runtime['druid.metadata.storage.connector.host'] ?= "#{my_ctx.config.host}"
          druid.common_runtime['druid.metadata.storage.connector.port'] ?= "#{my_ctx.config.postgres.server.port}"
        when 'derby'
          druid.common_runtime['druid.metadata.storage.type'] ?= 'derby'
          druid.common_runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:derby://#{@config.host}:1527/var/druid/metadata.db;create=true"
          druid.common_runtime['druid.metadata.storage.connector.host'] ?= "#{@config.host}"
          druid.common_runtime['druid.metadata.storage.connector.port'] ?= '1527'
      druid.common_runtime['druid.metadata.storage.connector.user'] ?= "#{druid.db.username}"
      druid.common_runtime['druid.metadata.storage.connector.password'] ?= "#{druid.db.password}"
      # For MySQL:
      #druid.common_runtime[druid.metadata.storage.type=mysql
      #druid.common_runtime[druid.metadata.storage.connector.connectURI=jdbc:mysql://db.example.com:3306/druid
      #druid.common_runtime[druid.metadata.storage.connector.user=...
      #druid.common_runtime[druid.metadata.storage.connector.password=...
      # For PostgreSQL (make sure to additionally include the Postgres extension):
      #druid.common_runtime[druid.metadata.storage.type=postgresql
      #druid.common_runtime[druid.metadata.storage.connector.connectURI=jdbc:postgresql://db.example.com:5432/druid
      #druid.common_runtime[druid.metadata.storage.connector.user=...
      #druid.common_runtime[druid.metadata.storage.connector.password=...
      # Deep storage
      # Extension "druid-hdfs-storage" added to "loadList"
      druid.common_runtime['druid.storage.type'] ?= 'hdfs'
      druid.common_runtime['druid.storage.storageDirectory'] ?= '/apps/druid/segments'
      # Indexing service logs
      druid.common_runtime['druid.indexer.logs.type'] ?= 'hdfs'
      druid.common_runtime['druid.indexer.logs.directory'] ?= '/apps/druid/indexing-logs'
      # Service discovery
      druid.common_runtime['druid.selectors.indexing.serviceName'] ?= 'druid/overlord'
      druid.common_runtime['druid.selectors.coordinator.serviceName'] ?= 'druid/coordinator'
      # Monitoring
      druid.common_runtime['druid.monitoring.monitors'] ?= '["com.metamx.metrics.JvmMonitor"]'
      druid.common_runtime['druid.emitter'] ?= 'logging'
      druid.common_runtime['druid.emitter.logging.logLevel'] ?= 'info'
