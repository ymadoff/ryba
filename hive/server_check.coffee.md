
# Hive Server Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Database

Check if Hive can authenticate and run a basic query to the database.

    module.exports.push name: 'Hive & HCat Server # Check Database', callback: (ctx, next) ->
      {hive_site, db_admin} = ctx.config.ryba
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
          , next
      return next new Error 'Database engine not supported' unless engines[engine]
      engines[engine]()

## Open Ports

    module.exports.push name: 'Hive & HCat Server # Check Open Port', callback: (ctx, next) ->
      {host} = ctx.config
      {hive_metastore_port, hive_server2_port} = ctx.config.ryba
      ctx.execute [
        {cmd: "echo > /dev/tcp/#{host}/#{hive_metastore_port}"}
        {cmd: "echo > /dev/tcp/#{host}/#{hive_server2_port}"}
      ], next

    module.exports.push name: 'Hive & HCat Server # Check', timeout: -1, callback: (ctx, next) ->
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
      # !connect jdbc:hive2://big3.big:10001/default;principal=hive/big3.big@ADALTAS.COM 
      next null, 'TODO'

# Module Dependencies

    parse_jdbc = require '../lib/parse_jdbc'


