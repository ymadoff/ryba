
# HBase Rest Gateway Check



    module.exports =  header: 'HBase Rest Check', timeout: -1, label_true: 'CHECKED', handler: ->
      {shortname} = @config
      {force_check, jaas_client, hbase} = @config.ryba
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

## Wait

      @wait once: true, 'ryba/hbase/rest/wait'

## Check Shell

      @execute
        cmd: mkcmd.test @, """
        #{curl} -X POST --data '#{schema}' #{protocol}://#{host}:#{port}/#{hbase.test.default_table}/schema
        #{curl} --data '#{rows}' #{protocol}://#{host}:#{port}/#{hbase.test.default_table}/___false-row-key___/#{shortname}_rest%3A
        #{curl} #{protocol}://#{host}:#{port}/#{hbase.test.default_table}/my_row_rest
        """
        unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"scan '#{hbase.test.default_table}', {COLUMNS => '#{shortname}_rest'}\" | egrep '[0-9]+ row'"
      , (err, executed, stdout) ->
        return if err or not executed
        try
          data = JSON.parse(stdout)
        catch e then throw Error "Invalid Command Output: #{JSON.stringify stdout}"
        return throw Error "Invalid ROW Key: #{JSON.stringify stdout}" unless decode(data?.Row[0]?.key) is 'my_row_rest'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
