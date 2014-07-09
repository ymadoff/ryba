---
title: 
layout: module
---

# HDP Hive & HCat Client Check

    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hive_client').configure ctx

## Check Metastore

Use the [Hive CLI][hivecli] client to execute SQL queries.

    module.exports.push name: 'HDP Hive & HCat Client Check # Metastore', timeout: -1, callback: (ctx, next) ->
      {test_user, hive_metastore_host, hive_metastore_port} = ctx.config.hdp
      ctx.waitIsOpen hive_metastore_host, hive_metastore_port, (err) ->
        host = ctx.config.host.split('.')[0]
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f #{ctx.config.host}-hive_metastore; then exit 2; fi
          hdfs dfs -mkdir -p #{ctx.config.host}-hive/check_metastore_tb
          echo -e 'a\0011\\nb\0012\\nc\0013' | hdfs dfs -put - #{ctx.config.host}-hive/check_metastore_tb/data
          hive -e "
            CREATE DATABASE IF NOT EXISTS check_#{host}_db LOCATION '/user/#{test_user.name}/#{ctx.config.host}-hive'; \\
            USE check_#{host}_db; \\
            CREATE TABLE IF NOT EXISTS check_metastore_tb(col1 STRING, col2 INT); \\
          "
          hive -S -e "SELECT SUM(col2) FROM check_#{host}_db.check_metastore_tb;" | hdfs dfs -put - #{ctx.config.host}-hive_metastore
          hive -e "DROP TABLE check_#{host}_db.check_metastore_tb; DROP DATABASE check_#{host}_db;"
          """
          code_skipped: 2
          trap_on_error: true
        , (err, executed, stdout) ->
          return next err, if executed then ctx.OK else ctx.PASS

## Check Server2

Use the [Beeline][beeline] JDBC client to execute SQL queries.

    module.exports.push name: 'HDP Hive & HCat Client Check # Server2', timeout: -1, callback: (ctx, next) ->
      {realm, test_user, hive_server2_host, hive_server2_port} = ctx.config.hdp
      url = "jdbc:hive2://#{hive_server2_host}:#{hive_server2_port}/default;principal=hive/#{hive_server2_host}@#{realm}"
      query = (query) -> "/usr/lib/hive/bin/beeline -u \"#{url}\" --silent=true -e \"#{query}\" "
      ctx.waitIsOpen hive_server2_host, hive_server2_port, (err) ->
        host = ctx.config.host.split('.')[0]
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f #{ctx.config.host}-hive_server2; then exit 2; fi
          hdfs dfs -mkdir -p #{ctx.config.host}-hive/check_server2_tb
          echo -e 'a\0011\\nb\0012\\nc\0013' | hdfs dfs -put - #{ctx.config.host}-hive/check_server2_tb/data
          #{query "CREATE DATABASE IF NOT EXISTS check_#{host}_db LOCATION '/user/#{test_user.name}/#{ctx.config.host}-hive'"}
          #{query "CREATE TABLE IF NOT EXISTS check_#{host}_db.check_server2_tb(col1 STRING, col2 INT) ;"}
          #{query "SELECT SUM(col2) FROM check_#{host}_db.check_server2_tb;"} | hdfs dfs -put - #{ctx.config.host}-hive_server2
          #{query "DROP TABLE check_#{host}_db.check_server2_tb;"}
          #{query "DROP DATABASE check_#{host}_db;"}
          """
          code_skipped: 2
          trap_on_error: true
        , (err, executed, stdout) ->
          next err, if executed then ctx.OK else ctx.PASS

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell

