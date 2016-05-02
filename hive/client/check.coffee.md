  
# Hive Client Check

This module check both the HCatalog and Hive Server2 servers respectively using
the commands "hive" and "beeline".

Debug mode in the "hive" command is activated with the "hive.root.logger"
parameter:

```
hive -hiveconf hive.root.logger=DEBUG,console
```

    module.exports =  header: 'Hive Client Check', label_true: 'CHECKED', timeout: -1, handler: ->
      {force_check, realm, user, hive} = @config.ryba

## Wait

      @call once: true, 'ryba/hive/hcatalog/wait'
      @call once: true, 'ryba/hive/server2/wait'

## Check HCatalog MapReduce

Use the [Hive CLI][hivecli] client to execute SQL queries using the MapReduce
engine.

      @call header: 'Check HCatalog MapReduce', label_true: 'CHECKED', timeout: -1, handler: ->
        for hcat_ctx in @contexts 'ryba/hive/hcatalog'
          directory = "check-#{@config.shortname}-hive_hcatalog_mr-#{hcat_ctx.config.shortname}"
          db = "check_#{@config.shortname}_hive_hcatalog_mr_#{hcat_ctx.config.shortname}"
          @execute
            cmd: mkcmd.test @, """
            hdfs dfs -rm -r -skipTrash #{directory} || true
            hdfs dfs -mkdir -p #{directory}/my_db/my_table
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
            hive -e "
              SET hive.execution.engine=mr;
              DROP TABLE IF EXISTS #{db}.my_table; DROP DATABASE IF EXISTS #{db};
              CREATE DATABASE #{db} LOCATION '/user/#{user.name}/#{directory}/my_db/';
              USE #{db};
              CREATE TABLE my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
            "
            hive -S -e "SET hive.execution.engine=mr; SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
            hive -e "DROP TABLE #{db}.my_table; DROP DATABASE #{db};"
            """
            unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
            trap: true

## Check HCatalog Tez

Use the [Hive CLI][hivecli] client to execute SQL queries using the Tez engine.

      @call header: 'Check HCatalog Tez', label_true: 'CHECKED', timeout: -1, handler: ->
        for hcat_ctx in @contexts 'ryba/hive/hcatalog'
          directory = "check-#{@config.shortname}-hive_hcatalog_tez-#{hcat_ctx.config.shortname}"
          db = "check_#{@config.shortname}_hive_hcatalog_tez_#{hcat_ctx.config.shortname}"
          @execute
            cmd: mkcmd.test @, """
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
            unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
            trap: true

## Check Server2

Use the [Beeline][beeline] JDBC client to execute SQL queries.

```
/usr/bin/beeline -d "org.apache.hive.jdbc.HiveDriver" -u "jdbc:hive2://{fqdn}:10001/;principal=hive/{fqdn}@{realm}"
```

The JDBC url may be provided inside the "-u" option or after the "!connect"
directive once you enter the beeline shell.

      @call
        header: 'Check Server2 (no ZK)'
        label_true: 'CHECKED'
        timeout: -1
        handler: ->
          for hs2_ctx in @contexts 'ryba/hive/server2'
            {hive} = hs2_ctx.config.ryba
            directory = "check-#{@config.shortname}-hive_server2-#{hs2_ctx.config.shortname}"
            db = "check_#{@config.shortname}_server2_#{hs2_ctx.config.shortname}"
            port = if hive.site['hive.server2.transport.mode'] is 'http'
            then hive.site['hive.server2.thrift.http.port']
            else hive.site['hive.server2.thrift.port']
            principal = hive.site['hive.server2.authentication.kerberos.principal']
            url = "jdbc:hive2://#{hs2_ctx.config.host}:#{port}/default;principal=#{principal}"
            if hive.site['hive.server2.use.SSL'] is 'true'
              url += ";ssl=true"
              url += ";sslTrustStore=#{hive.client.truststore_location}"
              url += ";trustStorePassword=#{hive.client.truststore_password}"
            if hive.site['hive.server2.transport.mode'] is 'http'
              url += ";transportMode=#{hive.site['hive.server2.transport.mode']}"
              url += ";httpPath=#{hive.site['hive.server2.thrift.http.path']}"
            beeline = "beeline -u \"#{url}\" --silent=true "
            @execute
              cmd: mkcmd.test @, """
              hdfs dfs -rm -r -f -skipTrash #{directory} || true
              hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
              echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
              #{beeline} \
              -e "DROP TABLE IF EXISTS #{db}.my_table;" \
              -e "DROP DATABASE IF EXISTS #{db};" \
              -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{directory}/my_db'" \
              -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
              #{beeline} \
              -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
              #{beeline} \
              -e "DROP TABLE #{db}.my_table;" \
              -e "DROP DATABASE #{db};"
              """
              unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
              trap: true

      @call
        header: 'Check Server2 (with ZK)'
        label_true: 'CHECKED'
        timeout: -1
        if: -> @contexts('ryba/hive/server2').length > 1
        handler: ->
          current = null;
          urls = @contexts 'ryba/hive/server2'
          .map (hs2_ctx) =>
            quorum = hs2_ctx.config.ryba.hive.site['hive.zookeeper.quorum']
            namespace = hs2_ctx.config.ryba.hive.site['hive.server2.zookeeper.namespace']
            principal = hs2_ctx.config.ryba.hive.site['hive.server2.authentication.kerberos.principal']
            url = "jdbc:hive2://#{quorum}/;principal=#{principal};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=#{namespace}"
            if hive.site['hive.server2.use.SSL'] is 'true'
              url += ";ssl=true"
              url += ";sslTrustStore=#{hive.client.truststore_location}"
              url += ";trustStorePassword=#{hive.client.truststore_password}"
            if hive.site['hive.server2.transport.mode'] is 'http'
              url += ";transportMode=#{hive.site['hive.server2.transport.mode']}"
              url += ";httpPath=#{hive.site['hive.server2.thrift.http.path']}"
            url
          .sort()
          .filter( (c) -> p = current; current = c; p isnt c )
          for url in urls
            namespace = /zooKeeperNamespace=(.*?)(;|$)/.exec(url)[1]
            directory = "check-#{@config.shortname}-hive_server2-zoo-#{namespace}"
            db = "check_#{@config.shortname}_hs2_zoo_#{namespace}"
            beeline = "beeline -u \"#{url}\" --silent=true "
            @execute
              cmd: mkcmd.test @, """
              hdfs dfs -rm -r -f -skipTrash #{directory} || true
              hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
              echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
              #{beeline} \
              -e "DROP TABLE IF EXISTS #{db}.my_table;" \
              -e "DROP DATABASE IF EXISTS #{db};" \
              -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{directory}/my_db'" \
              -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
              #{beeline} \
              -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
              #{beeline} \
              -e "DROP TABLE #{db}.my_table;" \
              -e "DROP DATABASE #{db};"
              """
              unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
              trap: true

## Check Sparl SQL Thrift Server
      
      @call once: true, if: (@contexts('ryba/spark/thrift_server').length > 0), 'ryba/spark/thrift_server/wait'
      @call
        header: 'Check Spark SQL Thrift Server'
        label_true: 'CHECKED'
        timeout: -1
        handler: ->
          for sts_ctx in @contexts 'ryba/spark/thrift_server'
            {hive} = sts_ctx.config.ryba
            directory = "check-#{@config.shortname}-spark-sql-server-#{sts_ctx.config.shortname}"
            db = "check_#{@config.shortname}_spark_sql_server_#{sts_ctx.config.shortname}"
            port = if hive.site['hive.server2.transport.mode'] is 'http'
            then hive.site['hive.server2.thrift.http.port']
            else hive.site['hive.server2.thrift.port']
            principal = hive.site['hive.server2.authentication.kerberos.principal']
            url = "jdbc:hive2://#{sts_ctx.config.host}:#{port}/default;principal=#{principal}"
            if hive.site['hive.server2.use.SSL'] is 'true'
              url += ";ssl=true"
              url += ";sslTrustStore=#{@config.ryba.hive.client.truststore_location}"
              url += ";trustStorePassword=#{@config.ryba.hive.client.truststore_password}"
            if hive.site['hive.server2.transport.mode'] is 'http'
              url += ";transportMode=#{hive.site['hive.server2.transport.mode']}"
              url += ";httpPath=#{hive.site['hive.server2.thrift.http.path']}"
            beeline = "beeline -u \"#{url}\" --silent=true "
            @execute
              cmd: mkcmd.test @, """
              hdfs dfs -rm -r -f -skipTrash #{directory} || true
              hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
              echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
              #{beeline} \
              -e "DROP TABLE IF EXISTS #{db}.my_table;" \
              -e "DROP DATABASE IF EXISTS #{db};" \
              -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{directory}/my_db'" \
              -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
              #{beeline} \
              -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
              #{beeline} \
              -e "DROP TABLE #{db}.my_table;" \
              -e "DROP DATABASE #{db};"
              """
              unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
              trap: true
              
## Dependencies

    mkcmd = require '../../lib/mkcmd'

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell
