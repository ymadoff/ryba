
# HBase Rest Gateway Check

    module.exports =  header: 'HBase Rest Check', timeout: -1, label_true: 'CHECKED', handler: ->
      {shortname} = @config
      {force_check, jaas_client, hbase, user} = @config.ryba
      encode = (data) -> (new Buffer data, 'utf8').toString 'base64'
      decode = (data) -> (new Buffer data, 'base64').toString 'utf8'
      curl = 'curl -s '
      curl += '-k ' if hbase.rest.site['hbase.rest.ssl.enabled'] is 'true'
      curl += '--negotiate -u: ' if hbase.rest.site['hbase.rest.authentication.type'] is 'kerberos'
      curl += '-H "Accept: application/json" '
      curl += '-H "Content-Type: application/json" '
      protocol = if hbase.rest.site['hbase.rest.ssl.enabled'] is 'true' then 'https' else 'http'
      host = @config.host
      shortname = @config.shortname
      port = hbase.rest.site['hbase.rest.port']
      schema = JSON.stringify ColumnSchema: [name: "#{shortname}_rest"]
      rows = JSON.stringify Row: [ key: encode('my_row_rest'), Cell: [column: encode("#{shortname}_rest:my_column"), $: encode('my rest value')]]
      [ranger_ctx] = @contexts 'ryba/ranger/admin'

## Ranger Policy
[Ranger HBase plugin][ranger-hbase] try to mimics grant/revoke by shell.

      @call
        if: -> ranger_ctx?
        handler: ->
          {install} = ranger_ctx.config.ryba.ranger.hbase_plugin
          policy_name = "Ranger-Ryba-HBase-Rest-Policy-#{@config.host}"
          hbase_policy =
            "name": "#{policy_name}"
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
                "values": [
                  "#{hbase.rest.test.namespace}:#{hbase.rest.test.table}"
                  ]
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
          @call once: true, 'ryba/ranger/admin/wait'
          @wait_execute
            header: 'Wait HBase Ranger repository'
            cmd: """
              curl --fail -H \"Content-Type: application/json\" -k -X GET  \
              -u admin:#{ranger_ctx.config.ryba.ranger.admin.password} \
              \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
            """
            code_skipped: 22
          @system.execute
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
              \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/#{policy_name}\"
            """

## Wait

      @call once: true, 'ryba/hbase/rest/wait'

## Check Shell

      @system.execute
        cmd: mkcmd.hbase @, """
        if hbase shell 2>/dev/null <<< "list_namespace_tables '#{hbase.rest.test.namespace}'" | egrep '[0-9]+ row'; then
          if [ ! -z '#{force_check or ''}' ]; then
            echo [DEBUG] Cleanup existing table and namespace
            hbase shell 2>/dev/null << '    CMD' | sed -e 's/^    //';
              disable '#{hbase.rest.test.namespace}:#{hbase.rest.test.table}'
              drop '#{hbase.rest.test.namespace}:#{hbase.rest.test.table}'
              drop_namespace '#{hbase.rest.test.namespace}'
            CMD
          else
            echo [INFO] Test is skipped; exit 2;
          fi
        fi
        hbase shell 2>/dev/null <<-CMD
          create_namespace '#{hbase.rest.test.namespace}'
          grant '#{user.name}', 'RWC', '@#{hbase.rest.test.namespace}'
          create '#{hbase.rest.test.namespace}:#{hbase.rest.test.table}', 'family1'
        CMD
        """
        code_skipped: 2
        trap: true
      @system.execute
        cmd: mkcmd.test @, """
        #{curl} -X POST --data '#{schema}' #{protocol}://#{host}:#{port}/#{hbase.rest.test.namespace}:#{hbase.rest.test.table}/schema
        #{curl} --data '#{rows}' #{protocol}://#{host}:#{port}/#{hbase.rest.test.namespace}:#{hbase.rest.test.table}/___false-row-key___/#{shortname}_rest%3A
        #{curl} #{protocol}://#{host}:#{port}/#{hbase.rest.test.namespace}:#{hbase.rest.test.table}/my_row_rest
        """
        unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"scan '#{hbase.rest.test.namespace}:#{hbase.rest.test.table}', {COLUMNS => '#{shortname}_rest'}\" | egrep '[0-9]+ row'"
      , (err, executed, stdout) ->
        return if err or not executed
        try
          data = JSON.parse(stdout)
        catch e then throw Error "Invalid Command Output: #{JSON.stringify stdout}"
        return throw Error "Invalid ROW Key: #{JSON.stringify stdout}" unless decode(data?.Row[0]?.key) is 'my_row_rest'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
