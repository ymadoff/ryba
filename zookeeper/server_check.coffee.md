---
title: 
layout: module
---

# Zookeeper Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./server').configure ctx

## Start ZooKeeper

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'ZooKeeper Server # Check Registration', callback: (ctx, next) ->
      {zookeeper_port} = ctx.config.hdp
      hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      ctx.waitIsOpen hosts, zookeeper_port, (err) ->
        return next err if err
        cmds = for host in hosts
          "{ echo conf; sleep 1; } | telnet #{host} #{zookeeper_port} 2>/dev/null | sed -n 's/.*serverId=\\(.*\\)/\\1/p'"
        ctx.execute
          cmd: cmds.join ';'
        , (err, _, stdout) ->
          unless stdout.trim().split('\n').sort().join(',') is [1..cmds.length].join(',')
            err = new Error "Servers are not properly registered" 
          next err, ctx.STABLE

