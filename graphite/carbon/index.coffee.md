
# Graphite Carbon

Graphite Carbon daemons make up the storage backend of a Graphite installation
All of the carbon daemons listen for time-series data and can accept it over a common set of protocols.
However, they differ in what they do with the data once they receive it.

    module.exports = []

## Configure

*   `carbon_user` (object|string)
    The Unix RRDtool login name or a user object (see Mecano User documentation).
*   `carbon_group` (object|string)
    The Unix Hue group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "ryba": {
    "graphite": {
      "carbon_user": {
        "name": "carbon", "system": true, "gid": "carbon", "shell": false
        "comment": "Graphite Carbon User", "home": "/usr/lib/carbon"
      }
      "carbon_group": {
        "name": "carbon", "system": true
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      #require('masson/core/iptables').configure ctx
      ctx.config.ryba ?= {}
      ctx.config.ryba.graphite ?= {}
      #ctx.config.ryba.graphite.carbon_user = name: ctx.config.ryba.carbon_user if typeof ctx.config.ryba.carbon_user is 'string'
      #ctx.config.ryba.graphite.carbon_user ?= {}
      #ctx.config.ryba.graphite.carbon_user.name ?= 'carbon'
      #ctx.config.ryba.graphite.carbon_user.system ?= true
      #ctx.config.ryba.graphite.carbon_user.gid = 'carbon'
      #ctx.config.ryba.graphite.carbon_user.shell = false
      #ctx.config.ryba.graphite.carbon_user.comment ?= 'Graphite Carbon User'
      #ctx.config.ryba.graphite.carbon_user.home = '/var/graphite/carbon'
      ## Group
      #ctx.config.ryba.graphite.carbon_group = name: ctx.config.ryba.carbon_group if typeof ctx.config.ryba.carbon_group is 'string'
      #ctx.config.ryba.graphite.carbon_group ?= {}
      #ctx.config.ryba.graphite.carbon_group.name ?= 'carbon'
      #ctx.config.ryba.graphite.carbon_group.system ?= true
      ## Ports
      ctx.config.ryba.graphite.carbon_port ?= 2023
      ctx.config.ryba.graphite.carbon_cache_port ?= 2003
      ctx.config.ryba.graphite.carbon_aggregator_port ?= 2023

      ctx.config.ryba.graphite.carbon_rewrite_rules ?= [
         '[pre]'
         '^(?P<cluster>\w+).(?P<bean>\w+).(?P<foobar>\w+).Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<foobar>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*port\x3D(?P<port>\w+).Context\x3D(?P<context>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<context>.\g<port>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*Queue\x3Droot(?P<queue>.\w+\b)*.Context\x3D(?P<context>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<context>.queue.\g<queue>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*Context\x3D(?P<context>\w+).ProcessName\x3D(?P<process>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<process>.\g<context>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*Context\x3D(?P<context>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<context>\g<metric>'
         'rpcdetailed = rpc'
         ]

      ctx.config.ryba.graphite.carbon_conf ?= [
         '[aggregator]'
         'LINE_RECEIVER_INTERFACE = 0.0.0.0'
         'LINE_RECEIVER_PORT = 2023'
         'PICKLE_RECEIVER_INTERFACE = 0.0.0.0'
         'PICKLE_RECEIVER_PORT = 2024'
         'LOG_LISTENER_CONNECTIONS = True'
         'FORWARD_ALL = True'
         'DESTINATIONS = 127.0.0.1:2004'
         'REPLICATION_FACTOR = 1'
         'MAX_QUEUE_SIZE = 10000'
         'USE_FLOW_CONTROL = True'
         'MAX_DATAPOINTS_PER_MESSAGE = 500'
         'MAX_AGGREGATION_INTERVALS = 5'
         '# WRITE_BACK_FREQUENCY = 0'
         ]

## Commands

    # module.exports.push command: 'backup', modules: 'ryba/graphite/carbon/backup'

    # module.exports.push commands: 'check', modules: 'ryba/graphite/carbon/check'

    # module.exports.push commands: 'install', modules: 'ryba/graphite/carbon/install'

    # module.exports.push commands: 'start', modules: 'ryba/graphite/carbon/start'

    # module.exports.push commands: 'status', modules: 'ryba/graphite/carbon/status'

    # module.exports.push commands: 'stop', modules: 'ryba/graphite/carbon/stop'
