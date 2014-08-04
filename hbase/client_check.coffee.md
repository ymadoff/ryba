
# HBase Client Check

Check the HBase client installation by creating a table, inserting a cell and
scanning the table.

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Configure

Retrieve the client configuration.

    module.exports.push (ctx) ->
      require('./client').configure ctx

## Shell

    module.exports.push name: 'HBase Client Check # Shell', timeout: -1, callback: (ctx, next) ->
      {jaas_client, hbase_conf_dir, hbase_user, hbase_group, shortname} = ctx.config.hdp
      cmd = mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"exists 'ryba'\" | grep 'Table ryba does exist'"
      ctx.waitForExecution cmd, (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hbase shell 2>/dev/null <<< "scan 'ryba', {COLUMNS => '#{shortname}'}" | egrep '[0-9]+ row'; then exit 2; fi
          hbase shell 2>/dev/null <<-CMD
            alter 'ryba', {NAME => '#{shortname}'}
            put 'ryba', 'my_row', '#{shortname}:my_column', 10
            scan 'ryba',  {COLUMNS => '#{shortname}'}
          CMD
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          isRowCreated = RegExp("column=#{shortname}:my_column, timestamp=\\d+, value=10").test stdout
          return next Error 'Invalid command output' if executed and not isRowCreated
          next err, if executed then ctx.OK else ctx.PASS
      # Note: inspiration for when namespace are functional
      # cmd = mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"list_namespace_tables 'ryba'\" | egrep '[0-9]+ row'"
      # ctx.waitForExecution cmd, (err) ->
      #   return next err if err
      #   ctx.execute
      #     cmd: mkcmd.test ctx, """
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
      #     return next Error 'Invalid command output' if executed and not isRowCreated
      #     return next err, if executed then ctx.OK else ctx.PASS

## Module Dependencies

    mkcmd = require '../hadoop/lib/mkcmd'