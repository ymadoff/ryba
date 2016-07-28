
# Hive HCatalog Check

    module.exports =  header: 'Hive HCatalog Check', label_true: 'CHECKED', handler: ->
      {hive, db_admin} = @config.ryba
      username = hive.site['javax.jdo.option.ConnectionUserName']
      password = hive.site['javax.jdo.option.ConnectionPassword']
      {engine, db} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']

## Wait

      @call once: true, 'ryba/hive/hcatalog/wait'

## Check Database

Check if Hive can authenticate and run a basic query to the database.

      @call header: 'Check Database', label_true: 'CHECKED', handler: ->  
        switch engine
          when 'mysql'
            escape = (text) -> text.replace(/[\\"]/g, "\\$&")
            @execute
              cmd: """
              #{db_admin.mysql.path} -u#{db_admin.mysql.username} -p#{db_admin.mysql.password} -h#{db_admin.mysql.host} -P#{db_admin.mysql.port} -e "USE #{db}; SHOW TABLES"
              """
          when 'postgresql'
            escape = (text) -> text.replace(/[\\"]/g, "\\$&")
            opts =
              host: db_admin.postgres.host
              port: db_admin.postgres.port
              name: db_admin.postgres.username
              password: db_admin.postgres.password
            @execute
              cmd: "#{database.wrap opts} -d #{db} -tAc \"\\dt\";"
          else throw Error 'Database engine not supported' unless engines[engine]

## Check Port

Check if the Hive HCatalog (Metastore) server is listening.

      @call header: 'Check Port', label_true: 'CHECKED', handler: ->
        uris = hive.site['hive.metastore.uris'].split ','
        [server] = for uri in uris
          {hostname, port} = url.parse uri
          continue unless hostname is @config.host
          host: hostname, port: port
        throw Error 'Invalid configuration' unless server
        @execute
          cmd: "echo > /dev/tcp/#{server.host}/#{server.port}"

# Module Dependencies

    url = require 'url'
    parse_jdbc = require '../../lib/parse_jdbc'
    database = require 'mecano/lib/misc/database'
