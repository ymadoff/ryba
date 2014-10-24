---
title: 
layout: module
---

# Hive Server

    module.exports = []

## Configure

Note, the following properties are required by knox in secured mode:

*   hive.server2.enable.doAs
*   hive.server2.allow.user.substitution
*   hive.server2.transport.mode
*   hive.server2.thrift.http.port
*   hive.server2.thrift.http.path

Example:

```json
{
  "ryba": {
    "hive_site": {
      "javax.jdo.option.ConnectionURL": "jdbc:mysql://front1.hadoop:3306/hive?createDatabaseIfNotExist=true"
      "javax.jdo.option.ConnectionDriverName": "com.mysql.jdbc.Driver"
      "javax.jdo.option.ConnectionUserName": "hive"
      "javax.jdo.option.ConnectionPassword": "hive123"
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/commons/mysql_server').configure ctx
      require('./_').configure ctx
      {hive_site, db_admin} = ctx.config.ryba
      # Layout
      ctx.config.ryba.hive_log_dir ?= '/var/log/hive'
      ctx.config.ryba.hive_pid_dir ?= '/var/run/hive'
      # Configuration
      hive_site['datanucleus.autoCreateTables'] ?= 'true'
      hive_site['hive.security.authorization.enabled'] ?= 'true'
      hive_site['hive.security.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive_site['hive.security.metastore.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive_site['hive.security.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.ProxyUserAuthenticator'
      hive_site['hive.server2.enable.doAs'] ?= 'true'
      hive_site['hive.server2.allow.user.substitution'] ?= 'true'
      hive_site['hive.server2.transport.mode'] ?= 'binary' # Kerberos not working with "http", see https://issues.apache.org/jira/browse/HIVE-6697
      hive_site['hive.server2.thrift.http.port'] ?= '10001'
      hive_site['hive.server2.thrift.port'] ?= '10001'
      hive_site['hive.server2.thrift.http.path'] ?= 'cliservice'
      ctx.config.ryba.hive_libs ?= []
      # Database
      if hive_site['javax.jdo.option.ConnectionURL']
        # Ensure the url host is the same as the one configured in config.ryba.db_admin
        {engine, hostname, port} = parse_jdbc hive_site['javax.jdo.option.ConnectionURL']
        switch engine
          when 'mysql'
            throw new Error "Invalid host configuration" if hostname isnt db_admin.host and port isnt db_admin.port
          else throw new Error 'Unsupported database engine'
      else
        switch db_admin.engine
          when 'mysql'
            hive_site['javax.jdo.option.ConnectionURL'] ?= "jdbc:mysql://#{db_admin.host}:#{db_admin.port}/hive?createDatabaseIfNotExist=true"
          else throw new Error 'Unsupported database engine'
      throw new Error "Hive database username is required" unless hive_site['javax.jdo.option.ConnectionUserName']
      throw new Error "Hive database password is required" unless hive_site['javax.jdo.option.ConnectionPassword']

    module.exports.push command: 'backup', modules: 'ryba/hive/server_backup'

    module.exports.push command: 'check', modules: 'ryba/hive/server_check'

    module.exports.push command: 'install', modules: 'ryba/hive/server_install'

    module.exports.push command: 'start', modules: 'ryba/hive/server_start'

    # module.exports.push command: 'status', modules: 'ryba/hive/server_status'

    module.exports.push command: 'stop', modules: 'ryba/hive/server_stop'

# Module Dependencies

    parse_jdbc = require '../lib/parse_jdbc'


