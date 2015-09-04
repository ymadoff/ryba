
# Zookeeper Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/zookeeper/server/wait'

## Check Registration

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'ZooKeeper Server # Check Registration', label_true: 'CHECKED', handler: ->
      {zookeeper} = @config.ryba
      zoo_ctxs = @contexts 'ryba/zookeeper/server', require('./').configure
      cmds = for zoo_ctx in zoo_ctxs
        "{ echo conf; sleep 1; } | telnet #{zoo_ctx.config.host} #{zoo_ctx.config.ryba.zookeeper.port} 2>/dev/null | sed -n 's/.*serverId=\\(.*\\)/\\1/p'"
      @execute
        cmd: cmds.join ';'
      , (err, _, stdout) ->
        return if err
        if zoo_ctxs.length is 1 # Standalone mode
          unless stdout.trim().split('\n').sort().join(',') is '0'
            throw Error "Server is not properly registered"
        else # Replicated mode
          throw Error unless /\d+/.test server for server in stdout.trim().split('\n')
          # The following test only pass if all zookeeper servers are started.
          # However, we dont wait for all servers to be started but only a
          # quorum of servers.
          # unless stdout.trim().split('\n').sort().join(',') is [1..cmds.length].join(',')
          #   throw Error "Servers are not properly registered"
