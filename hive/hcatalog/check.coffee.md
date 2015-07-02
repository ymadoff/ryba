
# Hive HCatalog Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hive/hcatalog/wait'
    module.exports.push require('./index').configure

## Check Database

Check if Hive can authenticate and run a basic query to the database.

    module.exports.push name: 'Hive HCatalog # Check Database', label_true: 'CHECKED', handler: (ctx, next) ->
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

## Check Port

Check if the Hive HCatalog (Metastore) server is listening.

    module.exports.push name: 'Hive HCatalog # Check Port', label_true: 'CHECKED', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      uris = hive.site['hive.metastore.uris'].split ','
      [server] = for uri in uris
        {hostname, port} = url.parse uri
        continue unless hostname is ctx.config.host
        host: hostname, port: port
      return next Error 'Invalid configuration' unless server
      ctx.execute
        cmd: "echo > /dev/tcp/#{server.host}/#{server.port}"
      .then next

# Module Dependencies

    url = require 'url'
    parse_jdbc = require '../../lib/parse_jdbc'


