
# Hive & HCat Client Check

    mkcmd = require '../lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hive/server_wait'
    module.exports.push require('./client').configure

## Check Server2

Use the [Beeline][beeline] JDBC client to execute SQL queries.

```
alias hs2=\'/usr/bin/beeline -d "org.apache.hive.jdbc.HiveDriver" -u "jdbc:hive2://{fqdn}:10001/;principal={hive}/fqdn@{realm}"
```

    module.exports.push name: 'Hive & HCat Client # Check Server2', label_true: 'CHECKED', timeout: -1, handler: (ctx, next) ->
      {force_check, realm, user, hive} = ctx.config.ryba
      hs2_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      return next() unless hs2_ctxs.length
      each(hs2_ctxs)
      .on 'item', (hs2_ctx, next) ->
        directory = "check-#{ctx.config.shortname}-hive_server2-#{hs2_ctx.config.shortname}"
        db = "check_#{ctx.config.shortname}_server2_#{hs2_ctx.config.shortname}"
        port = if hs2_ctx.config.ryba.hive.site['hive.server2.transport.mode'] is 'http'
        then hs2_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
        else hs2_ctx.config.ryba.hive.site['hive.server2.thrift.port']
        principal = hs2_ctx.config.ryba.hive.site['hive.server2.authentication.kerberos.principal']
        url = "jdbc:hive2://#{hs2_ctx.config.host}:#{port}/default;principal=#{principal}"
        beeline = "/usr/lib/hive/bin/beeline -u \"#{url}\" --silent=true -e"
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r -f -skipTrash #{directory} || true
          hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
          #{beeline} "
            DROP TABLE IF EXISTS #{db}.my_table;
            DROP DATABASE IF EXISTS #{db};
            CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{directory}/my_db'
            CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
          "
          #{beeline} "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
          #{beeline} "
            DROP TABLE #{db}.my_table;
            DROP DATABASE #{db};
          "
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -f #{directory}/result"
          trap_on_error: true
        , next
      .on 'both', next

## Check MapReduce

Use the [Hive CLI][hivecli] client to execute SQL queries using the MapReduce
engine.

    module.exports.push name: 'Hive & HCat Client # Check MapReduce', label_true: 'CHECKED', timeout: -1, handler: (ctx, next) ->
      {force_check, user} = ctx.config.ryba
      hcat_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      return next() unless hcat_ctxs.length
      each(hcat_ctxs)
      .on 'item', (hcat_ctx, next) ->
        directory = "check-#{ctx.config.shortname}-hive_hcatalog_mr-#{hcat_ctx.config.shortname}"
        db = "check_#{ctx.config.shortname}_hive_hcatalog_mr_#{hcat_ctx.config.shortname}"
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r #{directory} || true
          hdfs dfs -mkdir -p #{directory}/my_db/my_table
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
          hive -e "
            DROP TABLE IF EXISTS #{db}.my_table; DROP DATABASE IF EXISTS #{db};
            CREATE DATABASE #{db} LOCATION '/user/#{user.name}/#{directory}/my_db/';
            USE #{db};
            CREATE TABLE my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
          "
          hive -S -e "set hive.execution.engine=mapred; SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
          hive -e "DROP TABLE #{db}.my_table; DROP DATABASE #{db};"
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -f #{directory}/result"
          trap_on_error: true
        , next
      .on 'both', next

## Check Tez

Use the [Hive CLI][hivecli] client to execute SQL queries using the Tez engine.

    module.exports.push name: 'Hive & HCat Client # Check Tez', label_true: 'CHECKED', timeout: -1, handler: (ctx, next) ->
      {force_check, user} = ctx.config.ryba
      hcat_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      return next() unless hcat_ctxs.length
      each(hcat_ctxs)
      .on 'item', (hcat_ctx, next) ->
        directory = "check-#{ctx.config.shortname}-hive_hcatalog_tez-#{hcat_ctx.config.shortname}"
        db = "check_#{ctx.config.shortname}_hive_hcatalog_tez_#{hcat_ctx.config.shortname}"
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r -skipTrash #{directory} || true
          hdfs dfs -mkdir -p #{directory}/my_db/my_table
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
          hive -e "
            DROP TABLE IF EXISTS #{db}.my_table; DROP DATABASE IF EXISTS #{db};
            CREATE DATABASE #{db} LOCATION '/user/#{user.name}/#{directory}/my_db/';
            USE #{db};
            CREATE TABLE my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
          "
          hive -S -e "set hive.execution.engine=tez; SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
          hive -e "DROP TABLE #{db}.my_table; DROP DATABASE #{db};"
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -f #{directory}/result"
          trap_on_error: true
        , next
      .on 'both', next

## Dependencies

    each = require 'each'

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell

