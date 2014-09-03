
# Hive Server Check

    module.exports = []
    module.exports.push require('./server').configure

## Database

Check if Hive can authenticate and run a basic query to the database.

    module.exports.push name: 'Hive & HCat Server # Check Database', callback: (ctx, next) ->
      {hive_site, db_admin} = ctx.config.hdp
      username = hive_site['javax.jdo.option.ConnectionUserName']
      password = hive_site['javax.jdo.option.ConnectionPassword']
      {engine, db} = parse_jdbc hive_site['javax.jdo.option.ConnectionURL']
      engines = 
        mysql: ->
          escape = (text) -> text.replace(/[\\"]/g, "\\$&")
          cmd = " "
          ctx.execute
            cmd: """
            #{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "USE #{db}; SHOW TABLES"
            """
          , (err) ->
            return next err, ctx.PASS
      return next new Error 'Database engine not supported' unless engines[engine]
      engines[engine]()

## Open Ports

    module.exports.push name: 'Hive & HCat Server # Check Open Port', callback: (ctx, next) ->
      {host} = ctx.config
      {hive_metastore_port, hive_server2_port} = ctx.config.hdp
      ctx.execute [
        cmd: "echo > /dev/tcp/#{host}/#{hive_metastore_port}"
        trap_on_error: true
      ,
        cmd: "echo > /dev/tcp/#{host}/#{hive_server2_port}"
        trap_on_error: true
      ], (err) ->
        return next err, ctx.PASS

# Module Dependencies

    parse_jdbc = require '../lib/parse_jdbc'