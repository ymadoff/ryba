
## Configure

*   `carbon_user` (object|string)
    The Unix RRDtool login name or a user object (see Mecano User documentation).
*   `carbon_group` (object|string)
    The Unix Hue group name or a group object (see Mecano Group documentation).

Example:

```json
{ "ryba": { "graphite": {
      "carbon_user": {
        "name": "carbon", "system": true, "gid": "carbon", "shell": false
        "comment": "Graphite Carbon User", "home": "/usr/lib/carbon"
      }
      "carbon_group": {
        "name": "carbon", "system": true
      }
} } }
```

    module.exports = ->
      @config.ryba ?= {}
      graphite = @config.ryba.graphite ?= {}
      #@config.ryba.graphite.carbon_user = name: @config.ryba.carbon_user if typeof @config.ryba.carbon_user is 'string'
      #@config.ryba.graphite.carbon_user ?= {}
      #@config.ryba.graphite.carbon_user.name ?= 'carbon'
      #@config.ryba.graphite.carbon_user.system ?= true
      #@config.ryba.graphite.carbon_user.gid = 'carbon'
      #@config.ryba.graphite.carbon_user.shell = false
      #@config.ryba.graphite.carbon_user.comment ?= 'Graphite Carbon User'
      #@config.ryba.graphite.carbon_user.home = '/var/graphite/carbon'
      ## Group
      #@config.ryba.graphite.carbon_group = name: @config.ryba.carbon_group if typeof @config.ryba.carbon_group is 'string'
      #@config.ryba.graphite.carbon_group ?= {}
      #@config.ryba.graphite.carbon_group.name ?= 'carbon'
      #@config.ryba.graphite.carbon_group.system ?= true
      ## Ports
      graphite.carbon_port ?= 2023
      graphite.carbon_cache_port ?= 2003
      graphite.carbon_aggregator_port ?= 2023
      graphite.metrics_prefix ?= 'hadoop'
      graphite.carbon_rewrite_rules ?= [
         '[pre]'
         '^(?P<cluster>\w+).hbase.[a-zA-Z0-9_.,:;\x2d\x3D]*Context\x3D(?P<context>\w+).Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.hbase.\g<context>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).(?P<foobar>\w+).Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<foobar>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*port\x3D(?P<port>\w+).Context\x3D(?P<context>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<context>.\g<port>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*Queue\x3Droot(?P<queue>.\w+\b)*.Context\x3D(?P<context>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<context>.queue.\g<queue>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*Context\x3D(?P<context>\w+).ProcessName\x3D(?P<process>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<context>.\g<process>\g<metric>'
         '^(?P<cluster>\w+).(?P<bean>\w+).[a-zA-Z0-9_.\x3D]*Context\x3D(?P<context>\w+).[a-zA-Z0-9_.\x3D]*Hostname\x3D(?P<host>\w+).(?P<metric>.\w+)*$ = \g<cluster>.\g<host>.\g<context>\g<metric>'
         'rpcdetailed = rpc'
         ]

      graphite.carbon_conf ?= [
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
