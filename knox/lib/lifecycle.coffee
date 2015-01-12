
lifecyle = module.exports =
  gateway_status: (ctx, callback) ->
    {hdfs_pid_dir} = ctx.config.ryba
    ctx.log "Knox Gateway status"
    lifecyle.is_pidfile_running ctx, "/var/run/knox/knox.pid", (err, running) ->
      ctx.log "NameNode status: #{if running then 'RUNNING' else 'STOPPED'}"
      callback err, running
  gateway_start: (ctx, callback) ->
    {user} = ctx.config.knox
    lifecyle.nn_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Knox Gateway start"
      ctx.execute
        # su -l knox -c '/usr/lib/knox/bin/gateway.sh start'
        cmd: "su -l #{user.name} -c '/usr/lib/knox/bin/gateway.sh start'"
        code_skipped: 1
      , (err, started) ->
        return callback err if err
        callback err, started
  gateway_stop: (ctx, callback) ->
    {user} = ctx.config.knox
    lifecyle.nn_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Knox Gateway stop"
      ctx.execute
        # su -l knox -c '/usr/lib/knox/bin/gateway.sh stop'
        cmd: "su -l #{user.name} -c '/usr/lib/knox/bin/gateway.sh stop'"
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  gateway_restart: (ctx, callback) ->
    ctx.log "NameNode restart"
    lifecyle.gateway_stop ctx, (err) ->
      return callback err if err
      lifecyle.gateway_start ctx, callback






