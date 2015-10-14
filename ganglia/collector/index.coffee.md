
# Ganglia Collector

Ganglia Collector is the server which recieve data collected on each
host by the Ganglia Monitor agents.

    module.exports = []

## Configure

*   `rrdcached_user` (object|string)
    The Unix RRDtool login name or a user object (see Mecano User documentation).
*   `rrdcached_group` (object|string)
    The Unix Hue group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "ryba": {
    "ganglia": {
      "rrdcached_user": {
        "name": "rrdcached", "system": true, "gid": "rrdcached", "shell": false
        "comment": "RRDtool User", "home": "/usr/lib/rrdcached"
      }
      "rrdcached_group": {
        "name": "Hue", "system": true
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      ctx.config.ryba ?= {}
      ganglia = ctx.config.ryba.ganglia ?= {}
      ganglia.rrdcached_user = name: ctx.config.ryba.rrdcached_user if typeof ctx.config.ryba.rrdcached_user is 'string'
      ganglia.rrdcached_user ?= {}
      ganglia.rrdcached_user.name ?= 'rrdcached'
      ganglia.rrdcached_user.system ?= true
      ganglia.rrdcached_user.gid = 'rrdcached'
      ganglia.rrdcached_user.shell = false
      ganglia.rrdcached_user.comment ?= 'RRDtool User'
      ganglia.rrdcached_user.home = '/var/rrdtool/rrdcached'
      # Group
      ganglia.rrdcached_group = name: ctx.config.ryba.rrdcached_group if typeof ctx.config.ryba.rrdcached_group is 'string'
      ganglia.rrdcached_group ?= {}
      ganglia.rrdcached_group.name ?= 'rrdcached'
      ganglia.rrdcached_group.system ?= true
      # Ports
      ganglia.collector_port ?= 8649
      ganglia.slaves_port ?= 8660
      ganglia.hbase_region_port ?= ctx.config.ryba.ganglia.slaves_port
      ganglia.nn_port ?= 8661
      ganglia.jt_port ?= 8662
      ganglia.hm_port ?= 8663
      ganglia.hbase_master_port ?= ctx.config.ryba.ganglia.hm_port
      ganglia.rm_port ?= 8664
      ganglia.jhs_port ?= 8666
      ganglia.spark_port ?= 8667

## Commands

    # module.exports.push command: 'backup', modules: 'ryba/ganglia/collector/backup'

    # module.exports.push commands: 'check', modules: 'ryba/ganglia/collector/check'

    module.exports.push commands: 'install', modules: 'ryba/ganglia/collector/install'

    module.exports.push commands: 'start', modules: 'ryba/ganglia/collector/start'

    # module.exports.push commands: 'status', modules: 'ryba/ganglia/collector/status'

    module.exports.push commands: 'stop', modules: 'ryba/ganglia/collector/stop'
