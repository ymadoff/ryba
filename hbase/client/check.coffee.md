
# HBase Client Check

Check the HBase client installation by creating a table, inserting a cell and
scanning the table.

    module.exports =  header: 'HBase Client Check', label_true: 'CHECKED', handler: ->
      {shortname} = @config
      {force_check, hbase, user} = @config.ryba
      hbase_ctxs = @contexts 'ryba/hbase/master'
      {admin} = hbase_ctxs[0].config.ryba.hbase
      [ranger_ctx] = @contexts 'ryba/ranger/admin'

## Wait

Wait for the HBase master to be started.

      @call once: true, 'ryba/hbase/master/wait'
      @call once: true, 'ryba/hbase/regionserver/wait'

## Ranger Policy
[Ranger HBase plugin][ranger-hbase] try to mimics grant/revoke by shell.

      @call if: ranger_ctx, ->
        {install} = @config.ryba.ranger.hbase_plugin
        hbase_policy =
          "name": "Ranger-Ryba-HBase-Policy"
          "service": "#{install['REPOSITORY_NAME']}"
          "resources": 
            "column": 
              "values": ["*"]
              "isExcludes": false
              "isRecursive": false
            "column-family": 
              "values": ["*"]
              "isExcludes": false
              "isRecursive": false
            "table": 
              "values": ["#{hbase.client.test.namespace}:#{hbase.client.test.table}"]
              "isExcludes": false
              "isRecursive": false              	
          "repositoryName": "#{install['REPOSITORY_NAME']}"
          "repositoryType": "hbase"
          "isEnabled": "true",
          "isAuditEnabled": true,
          'tableType': 'Inclusion',
          'columnType': 'Inclusion',
          'policyItems': [
          		"accesses": [
          			'type': 'read'
          			'isAllowed': true
              ,
          			'type': 'write'
          			'isAllowed': true
          		,
          			'type': 'create'
          			'isAllowed': true
          		,
          			'type': 'admin'
          			'isAllowed': true
          		],
          		'users': ['hbase', "#{user.name}"]
          		'groups': []
          		'conditions': []
          		'delegateAdmin': true
            ]
            
## Wait

Wait for the HBase master to be started.

      @call once: true, 'ryba/hbase/master/wait'
      @call once: true, 'ryba/hbase/regionserver/wait'
      @call if:ranger_ctx?, once: true, 'ryba/ranger/admin/wait'

## Ranger Policy
[Ranger HBase plugin][ranger-hbase] try to mimics grant/revoke by shell.
      
      @call
        if: ranger_ctx?
        header:  'Create Ranger Policy'
        handler: ->
          @execute
            header: 'Ranger Ryba Policy'
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST \
              -d '#{JSON.stringify hbase_policy}' \
              -u admin:#{ranger_ctx.config.ryba.ranger.admin.password} \
              \"#{install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
            """
            unless_exec: """
              curl --fail -H \"Content-Type: application/json\" -k -X GET  \ 
              -u admin:#{ranger_ctx.config.ryba.ranger.admin.password} \
              \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/Ranger-Ryba-HBase-Policy\"
            """

## Shell

Create a "ryba" namespace and set full permission to the "ryba" user. This
namespace is used by other modules as a testing environment.  
Namespace and permissions are implemented and illustrated in [HBASE-8409].

Permissions is either zero or more letters from the set READ('R'), WRITE('W'), 
EXEC('X'), CREATE('C'), ADMIN('A'). Create and admin only apply to tables.

`grant <user|@group> <permissions> <table> [ <column family> [ <column qualifier> ] ]`

Groups and users access are revoked in the same way, but groups are prefixed 
with an '@' character. In the same way, tables and namespaces are specified, but
namespaces are prefixed with an '@' character.

      @execute
        header: 'Grant Permissions'
        cmd: mkcmd.hbase @, """
        if hbase shell 2>/dev/null <<< "list_namespace_tables '#{hbase.client.test.namespace}'" | egrep '[0-9]+ row'; then
          if [ ! -z '#{force_check or ''}' ]; then
            echo [DEBUG] Cleanup existing table and namespace
            hbase shell 2>/dev/null << '    CMD' | sed -e 's/^    //';
              disable '#{hbase.client.test.namespace}:#{hbase.client.test.table}'
              drop '#{hbase.client.test.namespace}:#{hbase.client.test.table}'
              drop_namespace '#{hbase.client.test.namespace}'
            CMD
          else
            echo [INFO] Test is skipped
            exit 2;
          fi
        fi
        echo '[DEBUG] Namespace level'
        hbase shell 2>/dev/null <<-CMD
          create_namespace '#{hbase.client.test.namespace}'
          grant '#{user.name}', 'RWC', '@#{hbase.client.test.namespace}'
        CMD
        echo '[DEBUG] Table Level'
        hbase shell 2>/dev/null <<-CMD
          create '#{hbase.client.test.namespace}:#{hbase.client.test.table}', 'family1'
          grant '#{user.name}', 'RWC', '#{hbase.client.test.namespace}:#{hbase.client.test.table}'
        CMD
        """
        code_skipped: 2
        trap: true

## Check Shell

Note, we are re-using the namespace created above.

      @call header: 'Shell', timeout: -1, label_true: 'CHECKED', handler: ->
        @wait_execute
          cmd: mkcmd.test @, "hbase shell 2>/dev/null <<< \"exists '#{hbase.client.test.namespace}:#{hbase.client.test.table}'\" | grep 'Table #{hbase.client.test.namespace}:#{hbase.client.test.table} does exist'"
        @execute
          cmd: mkcmd.test @, """
          hbase shell 2>/dev/null <<-CMD
            alter '#{hbase.client.test.namespace}:#{hbase.client.test.table}', {NAME => '#{shortname}'}
            put '#{hbase.client.test.namespace}:#{hbase.client.test.table}', 'my_row', '#{shortname}:my_column', 10
            scan '#{hbase.client.test.namespace}:#{hbase.client.test.table}',  {COLUMNS => '#{shortname}'}
          CMD
          """
          unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"scan '#{hbase.client.test.namespace}:#{hbase.client.test.table}', {COLUMNS => '#{shortname}'}\" | egrep '[0-9]+ row'"
        , (err, executed, stdout) ->
          isRowCreated = RegExp("column=#{shortname}:my_column, timestamp=\\d+, value=10").test stdout
          throw Error 'Invalid command output' if executed and not isRowCreated

## Check MapReduce

      @call header: 'MapReduce', timeout: -1, label_true: 'CHECKED', handler: ->
        @execute
          cmd: mkcmd.test @, """
            hdfs dfs -rm -skipTrash check-#{@config.host}-hbase-mapred
            echo -e '1,toto\\n2,tata\\n3,titi\\n4,tutu' | hdfs dfs -put -f - /user/ryba/test_import.csv
            hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator=, -Dimporttsv.columns=HBASE_ROW_KEY,family1:value #{hbase.client.test.namespace}:#{hbase.client.test.table} /user/ryba/test_import.csv
            hdfs dfs -touchz check-#{@config.host}-hbase-mapred
            """
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.host}-hbase-mapred"

## Check Splits

      @call header: 'Splits', timeout: -1, label_true: 'CHECKED', handler: ->
        {force_check} = @config.ryba
        @execute
          cmd: mkcmd.hbase @, """
            #if hbase shell 2>/dev/null <<< "list" | grep 'test_splits'; then echo "disable 'test_splits'; drop 'test_splits'" | hbase shell 2>/dev/null; fi
            echo "disable 'test_splits'; drop 'test_splits'" | hbase shell 2>/dev/null
            echo "create 'test_splits', 'cf1', SPLITS => ['1', '2', '3']" | hbase shell 2>/dev/null;
            echo "scan 'hbase:meta',  {COLUMNS => 'info:regioninfo', FILTER => \\"PrefixFilter ('test_split')\\"}" | hbase shell 2>/dev/null
            """
          unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"list 'test_splits'\" | grep -w 'test_splits'"
        , (err, executed, stdout) ->
          throw err if err
          return unless executed
          lines = string.lines stdout
          count = 0
          for line in lines
            count++ if /^ test_splits,/.test line
          throw Error 'Invalid Splits Count' unless count is 4

      # Note: inspiration for when namespace are functional
      # cmd = mkcmd.test @, "hbase shell 2>/dev/null <<< \"list_namespace_tables 'ryba'\" | egrep '[0-9]+ row'"
      # @waitForExecution cmd, (err) ->
      #   return  err if err
      #   @execute
      #     cmd: mkcmd.test @, """
      #     if hbase shell 2>/dev/null <<< "list_namespace_tables 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
      #     hbase shell 2>/dev/null <<-CMD
      #       create 'ryba.#{shortname}', 'family1'
      #       put 'ryba.#{shortname}', 'my_row', 'family1:my_column', 10
      #       scan 'ryba.#{shortname}'
      #     CMD
      #     """
      #     code_skipped: 2
      #   , (err, executed, stdout) ->
      #     isRowCreated = /column=family1:my_column10, timestamp=\d+, value=10/.test stdout
      #     return  Error 'Invalid command output' if executed and not isRowCreated
      #     return  err, executed


## Check HA

This check is only executed if more than two HBase Master are declared.

      @call header: 'HBase Client # Check HA', timeout: -1, label_true: 'CHECKED', handler: ->
        return unless hbase_ctxs.length > 1
        table = "check_#{@config.shortname}_ha"
        @execute
          cmd: mkcmd.hbase @, """
            # Create new table
            echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null
            echo "create '#{table}', 'cf1', {REGION_REPLICATION => 2}" | hbase shell 2>/dev/null;
            # Insert records
            echo "put '#{table}', 'my_row', 'cf1:my_column', 10" | hbase shell 2>/dev/null
            echo "scan '#{table}',  { CONSISTENCY => 'STRONG' }" | hbase shell 2>/dev/null
            echo "scan '#{table}',  { CONSISTENCY => 'TIMELINE' }" | hbase shell 2>/dev/null
            """
          # unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"list '#{table}'\" | grep -w '#{table}'"

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    string = require 'mecano/lib/misc/string'


[HBASE-8409]: https://issues.apache.org/jira/browse/HBASE-8409
[ranger-hbase]: https://cwiki.apache.org/confluence/display/RANGER/HBase+Plugin#HBasePlugin-Grantandrevoke
