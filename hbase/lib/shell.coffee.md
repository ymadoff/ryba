Wrappwe for HBase shell commands

    module.exports = (cmd) ->
      cmd = [cmd] unless Array.isArray cmd
      return Error 'command(s) provided is empty' unless cmd.length
      #""" hbase shell -n 2>/dev/null <<-CMD
      """ hbase_cmds=\"$(cat <<CMD
        #{cmd}
      CMD
      )\"
      echo \"$hbase_cmds\" | hbase shell -n 2>/dev/null
      """
