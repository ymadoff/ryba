
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

      @call header: 'Add HDFS Policy', if: ranger_admin?, ->
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

      @call header: 'Check HCatalog MapReduce', label_true: 'CHECKED', timeout: -1, ->
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

      @call header: 'Check HCatalog Tez', label_true: 'CHECKED', timeout: -1, ->
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

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell
