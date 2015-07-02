
# HBase Client Check

Check the HBase client installation by creating a table, inserting a cell and
scanning the table.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hbase/master/wait'
    module.exports.push require('./index').configure
    util = require 'util'

## Check Shell

    module.exports.push name: 'HBase Client # Check Shell', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {shortname} = ctx.config
      {force_check, jaas_client, hbase} = ctx.config.ryba
      cmd = mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"exists 'ryba'\" | grep 'Table ryba does exist'"
      ctx.waitForExecution cmd, (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          hbase shell 2>/dev/null <<-CMD
            alter 'ryba', {NAME => '#{shortname}'}
            put 'ryba', 'my_row', '#{shortname}:my_column', 10
            scan 'ryba',  {COLUMNS => '#{shortname}'}
          CMD
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"scan 'ryba', {COLUMNS => '#{shortname}'}\" | egrep '[0-9]+ row'"
        , (err, executed, stdout) ->
          isRowCreated = RegExp("column=#{shortname}:my_column, timestamp=\\d+, value=10").test stdout
          throw Error 'Invalid command output' if executed and not isRowCreated
        .then next

    module.exports.push name: 'HBase Client # Check MapReduce', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      ctx.execute
        cmd: mkcmd.test ctx, """
          echo -e '1,toto\\n2,tata\\n3,titi\\n4,tutu' | hdfs dfs -put -f - /user/ryba/test_import.csv
          hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator=, -Dimporttsv.columns=HBASE_ROW_KEY,family1:value ryba /user/ryba/test_import.csv
          """
      .then next

    module.exports.push name: 'HBase Client # Check Splits', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      hbase_ctxs = ctx.contexts 'ryba/hbase/master', require('../master').configure
      {admin} = hbase_ctxs[0].config.ryba.hbase
      ctx.execute
        cmd: mkcmd.hbase ctx, """
          if hbase shell 2>/dev/null <<< "list" | grep 'test_splits'; then echo "disable 'test_splits'" | hbase shell 2>/dev/null; echo "drop 'test_splits'" | hbase shell 2>/dev/null; fi
          echo "create 'test_splits', 'cf1', SPLITS => ['1', '2', '3']" | hbase shell 2>/dev/null;
          echo "scan 'hbase:meta',  {COLUMNS => 'info:regioninfo', FILTER => \\"PrefixFilter ('test_split')\\"}" | hbase shell 2>/dev/null
          """
      , (err, executed, stdout) ->
        return next err if err
        lines = string.lines stdout
        count = 0
        for line in lines
          count++ if /^ test_splits,/.test line
        throw Error 'Invalid Splits Count' unless count is 4
      .then next

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
      #     return next err, executed

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    string = require 'mecano/lib/misc/string'
