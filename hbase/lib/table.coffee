
module.exports = (options, callback) ->
  return callback Error 'Missing option "table"' unless options.table
  @execute
    cmd: """
    echo "create '#{options.table}', 'cf1', SPLITS => ['1', '2', '3']"
    """
    unless_exec: "hbase shell 2>/dev/null <<< \"exists '#{options.table}'\" | egrep '^Table .+ does exist$'"
  @execute
    cmd: """
    hbase shell 2>/dev/null <<< "enabled '#{options.table}'" | egrep '^true$'
    """
    if: options.enable
    unless_exec: "hbase shell 2>/dev/null <<< \"is_enabled '#{options.table}'\" | egrep '^true$'"
