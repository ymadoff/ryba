---
title: 
layout: module
---


# Ganglia Start


## Start Ganglia Server

Execute these commands on the Ganglia server host machine.

```coffee
module.exports.push (ctx, next) ->
  {oozie_user, oozie_log_dir} = ctx.config.hdp
  @name "HDP # Start Ganglia server"
  ctx.execute
    cmd: "/etc/init.d/hdp-gmetad start"
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS
```

## Start Ganglia Monitor

Execute this command on all the nodes in your Hadoop cluster.

```coffee
module.exports.push (ctx, next) ->
  {oozie_user, oozie_log_dir} = ctx.config.hdp
  @name "HDP # Start Ganglia Monitor"
  ctx.execute
    cmd: "/etc/init.d/hdp-gmond start"
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS
```
