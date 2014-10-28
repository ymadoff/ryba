---
title: Flume
module: ryba/hadoop/flume
layout: module
---

# Flume

Flume is a distributed, reliable, and available service for efficiently
collecting, aggregating, and moving large amounts of log data. It has a simple
and flexible architecture based on streaming data flows. It is robust and fault
tolerant with tunable reliability mechanisms and many failover and recovery
mechanisms.

    module.exports = []

## Configure

*   `flume_user` (object|string)   
    The Unix Flume login name or a user object (see Mecano User
    documentation).   
*   `flume_group` (object|string)   
    The Unix Flume group name or a group object (see Mecano Group
    documentation).   

Example:

```json
{
  "ryba": {
    "flume_user": {
      "name": "flume", "system": true, "gid": "flume"
      "comment": "Flume User", "home": "/var/lib/flume"
    }
    "flume_group": {
      "name": "flume", "system": true
    },
    "flume_conf_dir": "/etc/flume/conf"
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/krb5_client').configure ctx
      ctx.config.ryba ?= {}
      # User
      ctx.config.ryba.flume_user = name: ctx.config.ryba.flume_user if typeof ctx.config.ryba.flume_user is 'string'
      ctx.config.ryba.flume_user ?= {}
      ctx.config.ryba.flume_user.name ?= 'flume'
      ctx.config.ryba.flume_user.system ?= true
      ctx.config.ryba.flume_user.gid ?= 'flume'
      ctx.config.ryba.flume_user.comment ?= 'Flume User'
      ctx.config.ryba.flume_user.home ?= '/var/lib/flume'
      # Group
      ctx.config.ryba.flume_group = name: ctx.config.ryba.flume_group if typeof ctx.config.ryba.flume_group is 'string'
      ctx.config.ryba.flume_group ?= {}
      ctx.config.ryba.flume_group.name ?= 'flume'
      ctx.config.ryba.flume_group.system ?= true
      # Layout
      ctx.config.ryba.flume_conf_dir = '/etc/flume/conf'

    module.exports.push commands: 'install', modules: 'ryba/tools/flume_install'












