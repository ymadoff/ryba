
# Flume

[Flume](https://flume.apache.org/) is a distributed, reliable, and available service for efficiently
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
    "flume": {
      "user": {
        "name": "flume", "system": true, "gid": "flume",
        "comment": "Flume User", "home": "/var/lib/flume"
      },
      "group": {
        "name": "flume", "system": true
      },
      "conf_dir": "/etc/flume/conf"
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/krb5_client').configure ctx
      flume = ctx.config.ryba.flume ?= {}
      # User
      flume.user = name: flume.user if typeof flume.user is 'string'
      flume.user ?= {}
      flume.user.name ?= 'flume'
      flume.user.system ?= true
      flume.user.gid ?= 'flume'
      flume.user.comment ?= 'Flume User'
      flume.user.home ?= '/var/lib/flume'
      # Group
      flume.group = name: flume.group if typeof flume.group is 'string'
      flume.group ?= {}
      flume.group.name ?= 'flume'
      flume.group.system ?= true
      # Layout
      flume.conf_dir = '/etc/flume/conf'

    module.exports.push commands: 'install', modules: 'ryba/tools/flume/install'
