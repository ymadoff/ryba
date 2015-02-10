
# Hive Server Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Database

Check if Hive can authenticate and run a basic query to the database.

    module.exports.push name: 'Hive & HCat Server # Check Database', label_true: 'CHECKED', handler: (ctx, next) ->
      {hive, db_admin} = ctx.config.ryba
      username = hive.site['javax.jdo.option.ConnectionUserName']
      password = hive.site['javax.jdo.option.ConnectionPassword']
      {engine, db} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
      engines = 
        mysql: ->
          escape = (text) -> text.replace(/[\\"]/g, "\\$&")
          cmd = " "
          ctx.execute
            cmd: """
            #{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "USE #{db}; SHOW TABLES"
            """
          , next
      return next new Error 'Database engine not supported' unless engines[engine]
      engines[engine]()

## Open Port HCatalog

Check if the Hive HCatalog (Metastore) server is listening.

    module.exports.push name: 'Hive & HCat Server # Check Port HCatalog', label_true: 'CHECKED', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      uris = hive.site['hive.metastore.uris'].split ','
      servers = for uri in uris
        {hostname, port} = url.parse uri
        continue unless hostname is ctx.config.host
        host: hostname, port: port
      return next Error 'Invalid configuration' unless servers.length is 1
      ctx.execute
        cmd: "echo > /dev/tcp/#{servers[0].host}/#{servers[0].port}"
      , next

## Open Port Server2

Check if the Hive Server2 server is listening.

    module.exports.push name: 'Hive & HCat Server # Check Port Server2', label_true: 'CHECKED', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      port = if hive.site['hive.server2.transport.mode'] is 'http'
      then hive.site['hive.server2.thrift.http.port']
      else hive.site['hive.server2.thrift.port']
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{port}"
      , next

    module.exports.push name: 'Hive & HCat Server # Check', timeout: -1, handler: (ctx, next) ->
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
      # !connect jdbc:hive2://big3.big:10001/default;principal=hive/big3.big@ADALTAS.COM 
      next null, 'TODO'

# Module Dependencies

    url = require 'url'
    parse_jdbc = require '../lib/parse_jdbc'


