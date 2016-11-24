
# Hive Beeline Check

This module check the Hive Server2 servers using the `beeline` command.

    module.exports =  header: 'Hive Beeline Check', label_true: 'CHECKED', timeout: -1, handler: ->
      {force_check, realm, user, hive} = @config.ryba
      hive_server2 = @contexts 'ryba/hive/server2'
      spark_thrift_servers = @contexts 'ryba/spark/thrift_server'
      [ranger_admin] = @contexts 'ryba/ranger/admin'

## Wait

      @call once: true, 'ryba/hive/server2/wait'
      @call if: ranger_admin?, once: true, 'ryba/ranger/admin/wait'

## Add Ranger Policy 

      @call header: 'Add Hive Policy', if: ranger_admin?, handler: ->
        {install} = ranger_admin.config.ryba.ranger.hive_plugin
        dbs = []
        for hs2_ctx in hive_server2
          dbs.push "check_#{@config.shortname}_server2_#{hs2_ctx.config.shortname}"
          dbs.push "check_#{@config.shortname}_hs2_zoo_#{hs2_ctx.config.ryba.hive.server2.site['hive.server2.zookeeper.namespace']}"
        for hs_ctx in spark_thrift_servers
          dbs.push "check_#{@config.shortname}_spark_sql_server_#{hs_ctx.config.shortname}"
        # use v1 policy api (old style) from ranger to have an example
        hive_policy =
          "policyName": "Ranger-Ryba-HIVE-Policy-#{@config.host}"
          "repositoryName": "#{install['REPOSITORY_NAME']}"
          "repositoryType":"hive"
          "description": 'Ryba check hive policy'
          "databases": "#{dbs.join ','}"
          'tables': '*'
          "columns": "*"
          "udfs": ""
          'tableType': 'Inclusion'
          'columnType': 'Inclusion'
          'isEnabled': true
          'isAuditEnabled': true
          "permMapList": [{
          		"userList": ["#{user.name}"],
          		"permList": ["all"]
          	}]
        @wait_execute
          cmd: """
            curl --fail -H \"Content-Type: application/json\"   -k -X GET  \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
          """
          code_skipped: [1,7,22] #22 is for 404 not found,7 is for not connected to host
        @execute
          cmd: """
            curl --fail -H "Content-Type: application/json" -k -X POST \
            -d '#{JSON.stringify hive_policy}' \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/api/policy\"
          """
          unless_exec: """
            curl --fail -H \"Content-Type: application/json\" -k -X GET  \ 
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/Ranger-Ryba-HIVE-Policy-#{@config.host}\"
          """
          code_skippe: 22

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
      , ->
        for hs2_ctx in hive_server2
          # {hive} = hs2_ctx.config.ryba
          directory = "check-#{@config.shortname}-hive_server2-#{hs2_ctx.config.shortname}"
          db = "check_#{@config.shortname}_server2_#{hs2_ctx.config.shortname}"
          port = if hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
          then hs2_ctx.config.ryba.hive.server2.site['hive.server2.thrift.http.port']
          else hs2_ctx.config.ryba.hive.server2.site['hive.server2.thrift.port']
          principal = hs2_ctx.config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{hs2_ctx.config.host}:#{port}/default;principal=#{principal}"
          if hs2_ctx.config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{hive.client.truststore_location}"
            url += ";trustStorePassword=#{hive.client.truststore_password}"
          if hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode']}"
            url += ";httpPath=#{hs2_ctx.config.ryba.hive.server2.site['hive.server2.thrift.http.path']}"
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
        if: -> hive_server2.length > 1
        handler: ->
          current = null
          urls = hive_server2
          .map (hs2_ctx) ->
            quorum = hs2_ctx.config.ryba.hive.server2.site['hive.zookeeper.quorum']
            namespace = hs2_ctx.config.ryba.hive.server2.site['hive.server2.zookeeper.namespace']
            principal = hs2_ctx.config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']
            url = "jdbc:hive2://#{quorum}/;principal=#{principal};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=#{namespace}"
            if hs2_ctx.config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true'
              url += ";ssl=true"
              url += ";sslTrustStore=#{hive.client.truststore_location}"
              url += ";trustStorePassword=#{hive.client.truststore_password}"
            if hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
              url += ";transportMode=#{hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode']}"
              url += ";httpPath=#{hs2_ctx.config.ryba.hive.server2.site['hive.server2.thrift.http.path']}"
            url
          .sort()
          .filter (c) ->
            p = current; current = c; p isnt c
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

      @call once: true, if: (spark_thrift_servers.length > 0), 'ryba/spark/thrift_server/wait'
      @call
        header: 'Check Spark SQL Thrift Server'
        label_true: 'CHECKED'
        timeout: -1
        handler: ->
          for sts_ctx in spark_thrift_servers
            # {hive} = sts_ctx.config.ryba
            directory = "check-#{@config.shortname}-spark-sql-server-#{sts_ctx.config.shortname}"
            db = "check_#{@config.shortname}_spark_sql_server_#{sts_ctx.config.shortname}"
            port = if sts_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
            then sts_ctx.config.ryba.hive.server2.site['hive.server2.thrift.http.port']
            else sts_ctx.config.ryba.hive.server2.site['hive.server2.thrift.port']
            principal = sts_ctx.config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']
            url = "jdbc:hive2://#{sts_ctx.config.host}:#{port}/default;principal=#{principal}"
            if sts_ctx.config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true'
              url += ";ssl=true"
              url += ";sslTrustStore=#{@config.ryba.hive.client.truststore_location}"
              url += ";trustStorePassword=#{@config.ryba.hive.client.truststore_password}"
            if sts_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
              url += ";transportMode=#{sts_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode']}"
              url += ";httpPath=#{sts_ctx.config.ryba.hive.server2.site['hive.server2.thrift.http.path']}"
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
