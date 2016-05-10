
# Upgrade from HDP 2.3 to 2.4

## Procedure in pseudo-code

```
# on all nodes
./bin/ryba -c ./conf/env/offline.coffee install -m 'masson/**'  (should be done in hdfs upgrade)
# on all node
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hbase/master/install'
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hbase/regionserver/install
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hbase/rest/install'
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hbase/thrift/install'
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hbase/client/install'
# on master2 (standby)
hdp-select set hbase-master 2.4.0.0-169
service hbase-master restart
# on master1 (active)
hdp-select set hbase-master 2.4.0.0-169
service hbase-master restart
# on all regionservers, sequencially
hdp-select set hbase-regionserver 2.4.0.0-169 
service hbase-regionserver restart
# upgrade hbase-thrift server
hdp-select set hbase-client 2.4.0.0-169
service hbase-thrift restart
# upgrade hbase-rest server
hdp-select set hbase-client 2.4.0.0-169
service hbase-rest restart
```

## Source code

Follow official instruction from [Hortonworks HDP 2.2 Manual Upgrade][upgrade]

## Contexts

    exports = module.exports = []  
    
    exports.push
      header: 'Upgrade standby HBaseMaster'
      if: -> @has_module 'ryba/hbase/master'
      handler: ->
        zk_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
        zk_connect = zk_ctxs.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
        @call
          if_exec: mkcmd.hbase @, """
            zookeeper-client -server #{zk_connect} ls /hbase/backup-masters | grep '#{@config.host}'
          """
          handler: ->
            @register 'hdp_select', 'ryba/lib/hdp_select'
            @hdp_select
              name: 'hbase-master'
            @call 'ryba/hbase/master/stop'
            @call 'ryba/hbase/master/start'
            @call 'ryba/hbase/master/wait'

    exports.push
      header: 'Upgrade active HBaseMaster'
      if: -> @has_module 'ryba/hbase/master'
      handler: ->
        zk_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
        zk_connect = zk_ctxs.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
        @call
          unless_exec: mkcmd.hbase @, """
            zookeeper-client -server #{zk_connect} ls /hbase/backup-masters | grep '#{@config.host}'
          """
          handler: ->
            @register 'hdp_select', 'ryba/lib/hdp_select'
            @hdp_select
              name: 'hbase-master'
            @call 'ryba/hbase/master/stop'
            @call 'ryba/hbase/master/start'
            @call 'ryba/hbase/master/wait'

    exports.push
      header: 'Upgrade RegionServers'
      if: -> @has_module 'ryba/hbase/regionserver'
      handler: ->
        @call 'ryba/hbase/master/wait'
        @register 'hdp_select', 'ryba/lib/hdp_select'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-regionserver'
        @execute
          cmd: """
            service hbase-regionserver restart
          """
        @call (_, callback) ->
          setTimeout callback, 30000
            
    exports.push
      header: 'Upgrade HBase Thrift Server'
      if: -> @has_module 'ryba/hbase/thrift'
      handler: ->
        @call 'ryba/hbase/master/wait'
        @register 'hdp_select', 'ryba/lib/hdp_select'
        @hdp_select
          name: 'hbase-client'
        @execute
          cmd: """
            service hbase-thrift restart
          """
    exports.push
      header: 'Upgrade HBase Rest Server'
      if: -> @has_module 'ryba/hbase/rest'
      handler: ->
        @call 'ryba/hbase/master/wait'
        @register 'hdp_select', 'ryba/lib/hdp_select'
        @hdp_select
          name: 'hbase-client'
        @execute
          cmd: """
            service hbase-rest restart
          """  
                
    exports.push
      header: 'Configure standby HBase Masters'
      if: -> @has_module('ryba/hbase/master')
      handler: ->
        zk_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
        zk_connect = zk_ctxs.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
        @call
          if_exec: mkcmd.hbase @, """
            zookeeper-client -server #{zk_connect} ls /hbase/backup-masters | grep '#{@config.host}'
          """
          handler: ->
            @call 'ryba/hbase/master/install'
            @call 'ryba/hbase/master/stop'
            @call 'ryba/hbase/master/start'

    exports.push
      header: 'Configure active HBase Master'
      if: -> @has_module('ryba/hbase/master')
      handler: ->
        zk_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
        zk_connect = zk_ctxs.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
        @call
          unless_exec: mkcmd.hbase @, """
            zookeeper-client -server #{zk_connect} ls /hbase/backup-masters | grep '#{@config.host}'
          """
          handler: ->
            @call 'ryba/hbase/master/wait'
            @call 'ryba/hbase/master/install'
            @call 'ryba/hbase/master/stop'
            @call 'ryba/hbase/master/start'
            

    exports.push
      header: 'Configure HBase regionservers '
      if: -> @has_module('ryba/hbase/master')
      handler: ->
        zk_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
        zk_connect = zk_ctxs.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
        @call
          unless_exec: mkcmd.hbase @, """
            zookeeper-client -server #{zk_connect} ls /hbase/backup-masters | grep '#{@config.host}'
          """
          handler: ->
            @call 'ryba/hbase/regionserver/wait'
            @call 'ryba/hbase/regionserver/install'
            @call 'ryba/hbase/regionserver/stop'
            @call 'ryba/hbase/regionserver/start'
            @call (_, callback) ->
              setTimeout callback, 10000
  
    exports.push
      header: 'Configure HBase Rest Server '
      if: -> @has_module('ryba/hbase/rest')
      handler: ->
        @call 'ryba/hbase/rest/install'
        @call 'ryba/hbase/rest/stop'
        @call 'ryba/hbase/rest/start'
        @call 'ryba/hbase/rest/wait'

    exports.push
      header: 'Configure HBase Thrift Server '
      if: -> @has_module('ryba/hbase/rest')
      handler: ->
        @call 'ryba/hbase/rest/install'
        @call 'ryba/hbase/rest/stop'
        @call 'ryba/hbase/rest/start'
        @call 'ryba/hbase/rest/wait'


## Dependencies

    mkcmd = require '../mkcmd'
    # parse_jdbc = require '../parse_jdbc'
