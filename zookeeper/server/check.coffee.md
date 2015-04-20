
# Zookeeper Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure
    module.exports.push 'ryba/zookeeper/server/wait'

## Check Registration

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'ZooKeeper Server # Check Registration', label_true: 'CHECKED', handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      ctx.waitIsOpen hosts, zookeeper.port, (err) ->
        return next err if err
        cmds = for host in hosts
          "{ echo conf; sleep 1; } | telnet #{host} #{zookeeper.port} 2>/dev/null | sed -n 's/.*serverId=\\(.*\\)/\\1/p'"
        ctx.execute
          cmd: cmds.join ';'
        , (err, _, stdout) ->
          return next err if err
          if hosts.length is 1 # Standalone mode
            unless stdout.trim().split('\n').sort().join(',') is '0'
              err = new Error "Server is not properly registered"
          else # Replicated mode
            unless stdout.trim().split('\n').sort().join(',') is [1..cmds.length].join(',')
              err = new Error "Servers are not properly registered"
          next err, true
