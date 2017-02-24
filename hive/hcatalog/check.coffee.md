
# Hive HCatalog Check

    module.exports =  header: 'Hive HCatalog Check', label_true: 'CHECKED', handler: ->
      {hive} = @config.ryba
      username = hive.hcatalog.site['javax.jdo.option.ConnectionUserName']
      password = hive.hcatalog.site['javax.jdo.option.ConnectionPassword']
      jdbc = db.jdbc hive.hcatalog.site['javax.jdo.option.ConnectionURL']

## Wait

      @call once: true, 'ryba/hive/hcatalog/wait'

## Check Database

Check if Hive can authenticate and run a basic query to the database.

      @call header: 'Check Database', label_true: 'CHECKED', handler: ->  
        cmd = switch hive.hcatalog.db.engine
          when 'mysql' then 'SELECT * FROM VERSION'
          when 'postgres' then '\\dt'
        @system.execute
          cmd: db.cmd hive.hcatalog.db, admin_username: null, cmd

## Check Port

Check if the Hive HCatalog (Metastore) server is listening.

      @call header: 'Check Port', label_true: 'CHECKED', handler: ->
        uris = hive.hcatalog.site['hive.metastore.uris'].split ','
        [server] = for uri in uris
          {hostname, port} = url.parse uri
          continue unless hostname is @config.host
          host: hostname, port: port
        throw Error 'Invalid configuration' unless server
        @system.execute
          cmd: "echo > /dev/tcp/#{server.host}/#{server.port}"

# Module Dependencies

    url = require 'url'
    db = require 'mecano/lib/misc/db'
