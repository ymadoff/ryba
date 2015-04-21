
# HBase Rest Server Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hbase/regionserver/wait'
    # module.exports.push 'ryba/hbase/client' # Using `hbase shell` to wait before running the checks
    module.exports.push require('./index').configure

## Check Shell

    module.exports.push name: 'HBase Rest # Check', timeout: -1, skip: true, label_true: 'CHECKED', handler: (ctx, next) ->
      {shortname} = ctx.config
      {force_check, jaas_client, hbase} = ctx.config.ryba
      # cmd = mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"exists 'ryba'\" | grep 'Table ryba does exist'"
      # ctx.waitForExecution cmd, (err) ->
      #   return next err if err
      encode = (data) -> (new Buffer data, 'utf8').toString 'base64'
      decode = (data) -> (new Buffer data, 'base64').toString 'utf8'
      curl = 'curl -s '
      curl += '-k ' if hbase.site['hbase.rest.ssl.enabled'] is 'true'
      curl += '--negotiate -u: ' if hbase.site['hbase.rest.authentication.type'] is 'kerberos'
      curl += '-H "Accept: application/json" '
      curl += '-H "Content-Type: application/json" '
      protocol = if hbase.site['hbase.rest.ssl.enabled'] is 'true' then 'https' else 'http'
      host = ctx.config.host
      shortname = ctx.config.shortname
      port = hbase.site['hbase.rest.port']
      schema = JSON.stringify ColumnSchema: [name: "#{shortname}_rest"]
      rows = JSON.stringify Row: [ key: encode('my_row_rest'), Cell: [column: encode("#{shortname}_rest:my_column"), $: encode('my rest value')]]
      ctx.execute
        cmd: mkcmd.test ctx, """
        #{curl} -X POST --data '#{schema}' #{protocol}://#{host}:#{port}/ryba/schema
        #{curl} --data '#{rows}' #{protocol}://#{host}:#{port}/ryba/___false-row-key___/#{shortname}_rest%3A
        #{curl} #{protocol}://#{host}:#{port}/ryba/my_row_rest
        """
        not_if_exec: unless force_check then mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"scan 'ryba', {COLUMNS => '#{shortname}_rest'}\" | egrep '[0-9]+ row'"
      , (err, executed, stdout) ->
        return next err, false if err or not executed
        try
          data = JSON.parse(stdout)
        catch e then return next Error "Invalid Command Output: #{JSON.stringify stdout}"
        return next Error "Invalid ROW Key: #{JSON.stringify stdout}" unless decode(data?.Row[0]?.key) is 'my_row_rest'
        next err, executed

## Module Dependencies

    mkcmd = require '../../lib/mkcmd'
