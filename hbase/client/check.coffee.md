
# HBase Client Check

Check the HBase client installation by creating a table, inserting a cell and
scanning the table.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hbase/master/wait'
    # module.exports.push require('./index').configure

## Check Shell

    module.exports.push header: 'HBase Client # Check Shell', timeout: -1, label_true: 'CHECKED', handler: ->
      {shortname} = @config
      {force_check} = @config.ryba
      cmd = mkcmd.test @, "hbase shell 2>/dev/null <<< \"exists 'ryba'\" | grep 'Table ryba does exist'"
      @wait_execute
        cmd: cmd
      @execute
        cmd: mkcmd.test @, """
        hbase shell 2>/dev/null <<-CMD
          alter 'ryba', {NAME => '#{shortname}'}
          put 'ryba', 'my_row', '#{shortname}:my_column', 10
          scan 'ryba',  {COLUMNS => '#{shortname}'}
        CMD
        """
        unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"scan 'ryba', {COLUMNS => '#{shortname}'}\" | egrep '[0-9]+ row'"
      , (err, executed, stdout) ->
        isRowCreated = RegExp("column=#{shortname}:my_column, timestamp=\\d+, value=10").test stdout
        throw Error 'Invalid command output' if executed and not isRowCreated

## Check MapReduce

    module.exports.push header: 'HBase Client # Check MapReduce', timeout: -1, label_true: 'CHECKED', handler: ->
      {force_check} = @config.ryba
      @execute
        cmd: mkcmd.test @, """
          hdfs dfs -rm -skipTrash check-#{@config.host}-hbase-mapred
          echo -e '1,toto\\n2,tata\\n3,titi\\n4,tutu' | hdfs dfs -put -f - /user/ryba/test_import.csv
          hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator=, -Dimporttsv.columns=HBASE_ROW_KEY,family1:value ryba /user/ryba/test_import.csv
          hdfs dfs -touchz check-#{@config.host}-hbase-mapred
          """
        unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.host}-hbase-mapred"

## Check Splits

    module.exports.push header: 'HBase Client # Check Splits', timeout: -1, label_true: 'CHECKED', handler: ->
      {force_check} = @config.ryba
      hbase_ctxs = @contexts 'ryba/hbase/master'#, require('../master').configure
      {admin} = hbase_ctxs[0].config.ryba.hbase
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

    module.exports.push header: 'HBase Client # Check HA', timeout: -1, label_true: 'CHECKED', handler: ->
      {force_check} = @config.ryba
      hbase_ctxs = @contexts 'ryba/hbase/master', require('../master').configure
      return unless hbase_ctxs.length > 1
      {admin} = hbase_ctxs[0].config.ryba.hbase
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
