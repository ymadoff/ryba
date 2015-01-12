
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
      ctx.config.ryba.ganglia ?= {}
      ctx.config.ryba.ganglia.rrdcached_user = name: ctx.config.ryba.rrdcached_user if typeof ctx.config.ryba.rrdcached_user is 'string'
      ctx.config.ryba.ganglia.rrdcached_user ?= {}
      ctx.config.ryba.ganglia.rrdcached_user.name ?= 'rrdcached'
      ctx.config.ryba.ganglia.rrdcached_user.system ?= true
      ctx.config.ryba.ganglia.rrdcached_user.gid = 'rrdcached'
      ctx.config.ryba.ganglia.rrdcached_user.shell = false
      ctx.config.ryba.ganglia.rrdcached_user.comment ?= 'RRDtool User'
      ctx.config.ryba.ganglia.rrdcached_user.home = '/var/rrdtool/rrdcached'
      # Group
      ctx.config.ryba.ganglia.rrdcached_group = name: ctx.config.ryba.rrdcached_group if typeof ctx.config.ryba.rrdcached_group is 'string'
      ctx.config.ryba.ganglia.rrdcached_group ?= {}
      ctx.config.ryba.ganglia.rrdcached_group.name ?= 'rrdcached'
      ctx.config.ryba.ganglia.rrdcached_group.system ?= true
      # Ports
      ctx.config.ryba.ganglia.collector_port ?= 8649
      ctx.config.ryba.ganglia.slaves_port ?= 8660
      ctx.config.ryba.ganglia.nn_port ?= 8661
      ctx.config.ryba.ganglia.hm_port ?= 8663
      ctx.config.ryba.ganglia.rm_port ?= 8664
      ctx.config.ryba.ganglia.jhs_port ?= 8666

    # module.exports.push command: 'backup', modules: 'ryba/ganglia/collector_backup'

    # module.exports.push commands: 'check', modules: 'ryba/ganglia/collector_check'

    module.exports.push commands: 'install', modules: 'ryba/ganglia/collector_install'

    module.exports.push commands: 'start', modules: 'ryba/ganglia/collector_start'

    # module.exports.push commands: 'status', modules: 'ryba/ganglia/collector_status'

    module.exports.push commands: 'stop', modules: 'ryba/ganglia/collector_stop'




