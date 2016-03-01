

## Configure

*   `rrdcached_user` (object|string)
The Unix RRDtool login name or a user object (see Mecano User documentation).
*   `rrdcached_group` (object|string)
The Unix Hue group name or a group object (see Mecano Group documentation).

Example:

```json
{ "ryba": { "ganglia": {
  "rrdcached_user": {
    "name": "rrdcached", "system": true, "gid": "rrdcached", "shell": false
    "comment": "RRDtool User", "home": "/usr/lib/rrdcached"
  }
  "rrdcached_group": {
    "name": "Hue", "system": true
  }
}}}
```

    module.exports = ->
      @config.ryba ?= {}
      ganglia = @config.ryba.ganglia ?= {}
      ganglia.rrdcached_user = name: @config.ryba.rrdcached_user if typeof @config.ryba.rrdcached_user is 'string'
      ganglia.rrdcached_user ?= {}
      ganglia.rrdcached_user.name ?= 'rrdcached'
      ganglia.rrdcached_user.system ?= true
      ganglia.rrdcached_user.gid = 'rrdcached'
      ganglia.rrdcached_user.shell = false
      ganglia.rrdcached_user.comment ?= 'RRDtool User'
      ganglia.rrdcached_user.home = '/var/rrdtool/rrdcached'
      # Group
      ganglia.rrdcached_group = name: @config.ryba.rrdcached_group if typeof @config.ryba.rrdcached_group is 'string'
      ganglia.rrdcached_group ?= {}
      ganglia.rrdcached_group.name ?= 'rrdcached'
      ganglia.rrdcached_group.system ?= true
      # Ports
      ganglia.collector_port ?= 8649
      ganglia.slaves_port ?= 8660
      ganglia.hbase_region_port ?= @config.ryba.ganglia.slaves_port
      ganglia.nn_port ?= 8661
      ganglia.jt_port ?= 8662
      ganglia.hm_port ?= 8663
      ganglia.hbase_master_port ?= @config.ryba.ganglia.hm_port
      ganglia.rm_port ?= 8664
      ganglia.jhs_port ?= 8666
      ganglia.spark_port ?= 8667
