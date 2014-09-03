---
title: 
layout: module
---

# Hive & HCat Client Check

    mkcmd = require '../lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./client').configure ctx

## Check Metastore

Use the [Hive CLI][hivecli] client to execute SQL queries.

    module.exports.push name: 'Hive & HCat Client # Check Metastore', timeout: -1, callback: (ctx, next) ->
      {force_check, test_user, hive_metastore_host, hive_metastore_port} = ctx.config.ryba
      ctx.waitIsOpen hive_metastore_host, hive_metastore_port, (err) ->
        host = ctx.config.shortname
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r check-#{host}-hive_metastore || true
          hdfs dfs -mkdir -p check-#{host}-hive_metastore/my_db/my_table
          echo -e 'a\0011\\nb\0012\\nc\0013' | hdfs dfs -put - check-#{host}-hive_metastore/my_db/my_table/data
          hive -e "
            DROP TABLE IF EXISTS check_#{host}_metastore.my_table; DROP DATABASE IF EXISTS check_#{host}_metastore;
            CREATE DATABASE check_#{host}_metastore LOCATION '/user/#{test_user.name}/check-#{host}-hive_metastore/my_db/'; \\
            USE check_#{host}_metastore; \\
            CREATE TABLE my_table(col1 STRING, col2 INT); \\
          "
          hive -S -e "SELECT SUM(col2) FROM check_#{host}_metastore.my_table;" | hdfs dfs -put - check-#{host}-hive_metastore/result
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -f check-#{host}-hive_metastore/result"
          trap_on_error: true
        , (err, executed, stdout) ->
          return next err, if executed then ctx.OK else ctx.PASS

## Check Server2

Use the [Beeline][beeline] JDBC client to execute SQL queries.

    module.exports.push name: 'Hive & HCat Client # Check Server2', timeout: -1, callback: (ctx, next) ->
      {force_check, realm, test_user, hive_server2_host, hive_server2_port} = ctx.config.ryba
      url = "jdbc:hive2://#{hive_server2_host}:#{hive_server2_port}/default;principal=hive/#{hive_server2_host}@#{realm}"
      query = (query) -> "/usr/lib/hive/bin/beeline -u \"#{url}\" --silent=true -e \"#{query}\" "
      ctx.waitIsOpen hive_server2_host, hive_server2_port, (err) ->
        host = ctx.config.shortname
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r check-#{host}-hive_server2 || true
          hdfs dfs -mkdir -p check-#{host}-hive_server2/my_db/my_table
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{host}-hive_server2/my_db/my_table/data
          #{query "DROP TABLE IF EXISTS check_#{host}_server2.my_table; DROP DATABASE IF EXISTS check_#{host}_server2;"}
          #{query "CREATE DATABASE IF NOT EXISTS check_#{host}_server2 LOCATION '/user/#{test_user.name}/check-#{host}-hive_server2/my_db'"}
          #{query "CREATE TABLE IF NOT EXISTS check_#{host}_server2.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"}
          #{query "SELECT SUM(col2) FROM check_#{host}_server2.my_table;"} | hdfs dfs -put - check-#{host}-hive_server2/result
          #{query "DROP TABLE check_#{host}_server2.my_table;"}
          #{query "DROP DATABASE check_#{host}_server2;"}
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -f check-#{host}-hive_server2/result"
          trap_on_error: true
        , (err, executed, stdout) ->
          next err, if executed then ctx.OK else ctx.PASS

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell

