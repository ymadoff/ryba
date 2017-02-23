
# Hive Client Check

This module check the HCatalog server using the `hive` command.

Debug mode in the "hive" command is activated with the "hive.root.logger"
parameter:

```
hive -hiveconf hive.root.logger=DEBUG,console
```

    module.exports =  header: 'Hive Client Check', label_true: 'CHECKED', timeout: -1, handler: ->
      {force_check, realm, user, hive} = @config.ryba
      [ranger_admin] = @contexts 'ryba/ranger/admin'
      hive_hcatalog = @contexts 'ryba/hive/hcatalog'

## Wait

      @call once: true, 'ryba/hive/hcatalog/wait'
      @call if: ranger_admin?, once: true, 'ryba/ranger/admin/wait'

## Add Ranger Policy 
hive client is communicating directly with hcatalog, which means that on a ranger
managed cluster, ACL must be set on HDFS an not on hive.

      @call header: 'Add HDFS Policy', if: ranger_admin?, handler: ->
        {install} = ranger_admin.config.ryba.ranger.hdfs_plugin
        name = "Ranger-Ryba-HDFS-Policy-#{@config.host}-client"
        dbs = []
        directories = []
        for h_ctx in hive_hcatalog
          directories.push "check-#{@config.shortname}-hive_hcatalog_mr-#{h_ctx.config.shortname}"
          directories.push "check-#{@config.shortname}-hive_hcatalog_tez-#{h_ctx.config.shortname}"
        hdfs_policy =
          name: "#{name}"
          service: "#{install['REPOSITORY_NAME']}"
          repositoryType:"hdfs"
          description: 'Hive Client Check'
          isEnabled: true
          isAuditEnabled: true
          resources:
            path:
              isRecursive: 'true'
              values: directories
              isExcludes: false
          policyItems: [{
            users: ["#{user.name}"]
            groups: []
            delegateAdmin: true
            accesses:[
                "isAllowed": true
                "type": "read"
            ,
                "isAllowed": true
                "type": "write"
            ,
                "isAllowed": true
                "type": "execute"
            ]
            conditions: []
            }]
        @system.execute
          cmd: """
            curl --fail -H "Content-Type: application/json" -k -X POST \
            -d '#{JSON.stringify hdfs_policy}' \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
          """
          unless_exec: """
            curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/#{hdfs_policy.name}"
          """
          code_skippe: 22

## Check HCatalog MapReduce

Use the [Hive CLI][hivecli] client to execute SQL queries using the MapReduce
engine.

      @call header: 'Check HCatalog MapReduce', label_true: 'CHECKED', timeout: -1, handler: ->
        for hcat_ctx in hive_hcatalog
          directory = "check-#{@config.shortname}-hive_hcatalog_mr-#{hcat_ctx.config.shortname}"
          db = "check_#{@config.shortname}_hive_hcatalog_mr_#{hcat_ctx.config.shortname}"
          @system.execute
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
        for hcat_ctx in hive_hcatalog
          directory = "check-#{@config.shortname}-hive_hcatalog_tez-#{hcat_ctx.config.shortname}"
          db = "check_#{@config.shortname}_hive_hcatalog_tez_#{hcat_ctx.config.shortname}"
          @system.execute
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

# ## Check Server2
# 
# Use the [Beeline][beeline] JDBC client to execute SQL queries.
# 
# ```
# /usr/bin/beeline -d "org.apache.hive.jdbc.HiveDriver" -u "jdbc:hive2://{fqdn}:10001/;principal=hive/{fqdn}@{realm}"
# ```
# 
# The JDBC url may be provided inside the "-u" option or after the "!connect"
# directive once you enter the beeline shell.
# 
#       @call
#         header: 'Check Server2 (no ZK)'
#         label_true: 'CHECKED'
#         timeout: -1
#         handler: ->
#           for hs2_ctx in hive_server2
#             {hive} = hs2_ctx.config.ryba
#             directory = "check-#{@config.shortname}-hive_server2-#{hs2_ctx.config.shortname}"
#             db = "check_#{@config.shortname}_server2_#{hs2_ctx.config.shortname}"
#             port = if hive.server2.site['hive.server2.transport.mode'] is 'http'
#             then hive.server2.site['hive.server2.thrift.http.port']
#             else hive.server2.site['hive.server2.thrift.port']
#             principal = hive.server2.site['hive.server2.authentication.kerberos.principal']
#             url = "jdbc:hive2://#{hs2_ctx.config.host}:#{port}/default;principal=#{principal}"
#             if hive.server2.site['hive.server2.use.SSL'] is 'true'
#               url += ";ssl=true"
#               url += ";sslTrustStore=#{hive.client.truststore_location}"
#               url += ";trustStorePassword=#{hive.client.truststore_password}"
#             if hive.server2.site['hive.server2.transport.mode'] is 'http'
#               url += ";transportMode=#{hive.server2.site['hive.server2.transport.mode']}"
#               url += ";httpPath=#{hive.server2.site['hive.server2.thrift.http.path']}"
#             beeline = "beeline -u \"#{url}\" --silent=true "
#             @system.execute
#               cmd: mkcmd.test @, """
#               hdfs dfs -rm -r -f -skipTrash #{directory} || true
#               hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
#               echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
#               #{beeline} \
#               -e "DROP TABLE IF EXISTS #{db}.my_table;" \
#               -e "DROP DATABASE IF EXISTS #{db};" \
#               -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{directory}/my_db'" \
#               -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
#               #{beeline} \
#               -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
#               #{beeline} \
#               -e "DROP TABLE #{db}.my_table;" \
#               -e "DROP DATABASE #{db};"
#               """
#               unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
#               trap: true
#       @call
#         header: 'Check Server2 (with ZK)'
#         label_true: 'CHECKED'
#         timeout: -1
#         if: -> hive_server2.length > 1
#         handler: ->
#           current = null
#           urls = hive_server2
#           .map (hs2_ctx) ->
#             quorum = hs2_ctx.config.ryba.hive.server2.site['hive.zookeeper.quorum']
#             namespace = hs2_ctx.config.ryba.hive.server2.site['hive.server2.zookeeper.namespace']
#             principal = hs2_ctx.config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']
#             url = "jdbc:hive2://#{quorum}/;principal=#{principal};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=#{namespace}"
#             if hive.server2.site['hive.server2.use.SSL'] is 'true'
#               url += ";ssl=true"
#               url += ";sslTrustStore=#{hive.client.truststore_location}"
#               url += ";trustStorePassword=#{hive.client.truststore_password}"
#             if hive.server2.site['hive.server2.transport.mode'] is 'http'
#               url += ";transportMode=#{hive.server2.site['hive.server2.transport.mode']}"
#               url += ";httpPath=#{hive.server2.site['hive.server2.thrift.http.path']}"
#             url
#           .sort()
#           .filter (c) ->
#             p = current; current = c; p isnt c
#           for url in urls
#             namespace = /zooKeeperNamespace=(.*?)(;|$)/.exec(url)[1]
#             directory = "check-#{@config.shortname}-hive_server2-zoo-#{namespace}"
#             db = "check_#{@config.shortname}_hs2_zoo_#{namespace}"
#             beeline = "beeline -u \"#{url}\" --silent=true "
#             @system.execute
#               cmd: mkcmd.test @, """
#               hdfs dfs -rm -r -f -skipTrash #{directory} || true
#               hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
#               echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
#               #{beeline} \
#               -e "DROP TABLE IF EXISTS #{db}.my_table;" \
#               -e "DROP DATABASE IF EXISTS #{db};" \
#               -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{directory}/my_db'" \
#               -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
#               #{beeline} \
#               -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
#               #{beeline} \
#               -e "DROP TABLE #{db}.my_table;" \
#               -e "DROP DATABASE #{db};"
#               """
#               unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
#               trap: true
# 
# ## Check Sparl SQL Thrift Server
# 
#       @call once: true, if: (spark_thrift_server.length > 0), 'ryba/spark/thrift_server/wait'
#       @call
#         header: 'Check Spark SQL Thrift Server'
#         label_true: 'CHECKED'
#         timeout: -1
#         handler: ->
#           for sts_ctx in spark_thrift_server
#             {hive} = sts_ctx.config.ryba
#             directory = "check-#{@config.shortname}-spark-sql-server-#{sts_ctx.config.shortname}"
#             db = "check_#{@config.shortname}_spark_sql_server_#{sts_ctx.config.shortname}"
#             port = if hive.server2.site['hive.server2.transport.mode'] is 'http'
#             then hive.server2.site['hive.server2.thrift.http.port']
#             else hive.server2.site['hive.server2.thrift.port']
#             principal = hive.server2.site['hive.server2.authentication.kerberos.principal']
#             url = "jdbc:hive2://#{sts_ctx.config.host}:#{port}/default;principal=#{principal}"
#             if hive.server2.site['hive.server2.use.SSL'] is 'true'
#               url += ";ssl=true"
#               url += ";sslTrustStore=#{@config.ryba.hive.client.truststore_location}"
#               url += ";trustStorePassword=#{@config.ryba.hive.client.truststore_password}"
#             if hive.server2.site['hive.server2.transport.mode'] is 'http'
#               url += ";transportMode=#{hive.server2.site['hive.server2.transport.mode']}"
#               url += ";httpPath=#{hive.server2.site['hive.server2.thrift.http.path']}"
#             beeline = "beeline -u \"#{url}\" --silent=true "
#             @system.execute
#               cmd: mkcmd.test @, """
#               hdfs dfs -rm -r -f -skipTrash #{directory} || true
#               hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
#               echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
#               #{beeline} \
#               -e "DROP TABLE IF EXISTS #{db}.my_table;" \
#               -e "DROP DATABASE IF EXISTS #{db};" \
#               -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{directory}/my_db'" \
#               -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
#               #{beeline} \
#               -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
#               #{beeline} \
#               -e "DROP TABLE #{db}.my_table;" \
#               -e "DROP DATABASE #{db};"
#               """
#               unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
#               trap: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell
