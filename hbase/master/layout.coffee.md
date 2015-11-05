
    module.exports = header: 'HBase Master Layout', handler: ->
      @call header: 'HBase Master # HDFS layout', timeout: -1, handler: ->
        {hbase} = @config.ryba
        @wait_execute
          cmd: mkcmd.hdfs @, "hdfs dfs -test -d /apps"
        @call ->
          dirs = hbase.site['hbase.bulkload.staging.dir'].split '/'
          throw err "Invalid property \"hbase.bulkload.staging.dir\"" unless dirs.length > 2 and path.join('/', dirs[0], '/', dirs[1]) is '/apps'
          for dir, index in dirs.slice 2
            dir = dirs.slice(0, 3 + index).join '/'
            cmd = """
            if hdfs dfs -ls #{dir} &>/dev/null; then exit 2; fi
            hdfs dfs -mkdir #{dir}
            hdfs dfs -chown #{hbase.user.name} #{dir}
            """
            cmd += "\nhdfs dfs -chmod 711 #{dir}"  if 3 + index is dirs.length
            @execute
              cmd: mkcmd.hdfs @, cmd
              code_skipped: 2

# Module dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
      
