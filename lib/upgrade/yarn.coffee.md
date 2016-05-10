
# Upgrade from HDP 2.3 to 2.4

## Procedure in pseudo-code

```
# on all nodes
./bin/ryba -c ./conf/env/offline.coffee install -m 'masson/**'  (should be done in hdfs upgrade)
# on all node
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hadoop/mapred_jhs/*'
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hadoop/mapred_ts/*'
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hadoop/yarn_rm/*'
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/hadoop/yarn_nm/*'
# upgrade and restart timelineserver 
hdp-select set hadoop-yarn-timelineserver 2.4.0.0-169
service hadoop-yarn-timelineserver restart
# upgrade and restart mapred history server
hdp-select set hadoop-mapreduce-historyserver 2.4.0.0-169 
service hadoop-mapreduce-historyserver restart
# on rm2 (standby)
hdp-select set hadoop-yarn-resourcemanager 2.4.0.0-169
service hadoop-yarn-resourcemanager restart
wait until echo > /dev/tcp/master2/8090
# on rm1 (active)
hdp-select set hadoop-yarn-resourcemanager 2.4.0.0-169
service hadoop-yarn-resourcemanager restart
wait until echo > /dev/tcp/master1/8090
# on all nodemanager nodes, sequencially
hdp-select set hadoop-yarn-nodemanager 2.4.0.0-169
service adoop-yarn-nodemanager restart
```

## Source code

Follow official instruction from [Hortonworks HDP 2.2 Manual Upgrade][upgrade]

    exports = module.exports = []
    exports.push
      header: 'Upgrade Yarn TS'
      if: -> @has_module 'ryba/hadoop/yarn_ts'
      handler: ->
        @register 'hdp_select', 'ryba/lib/hdp_select'
        @hdp_select
          name: 'hadoop-yarn-timelineserver'
        @call 'ryba/hadoop/yarn_ts/stop'
        @call 'ryba/hadoop/yarn_ts/start'
        @call 'ryba/hadoop/yarn_ts/wait'

    exports.push
      header: 'Upgrade Mapred JHS'
      if: -> @has_module 'ryba/hadoop/mapred_jhs'
      handler: ->
        @register 'hdp_select', 'ryba/lib/hdp_select'
        @hdp_select
          name: 'hadoop-mapreduce-historyserver'
        @call 'ryba/hadoop/mapred_jhs/stop'
        @call 'ryba/hadoop/mapred_jhs/start'
        @call 'ryba/hadoop/mapred_jhs/wait'

    exports.push
      header: 'Upgrade standby ResourceManager'
      if: -> @has_module 'ryba/hadoop/yarn_rm'
      handler: ->
        @call 'ryba/hadoop/yarn_ts/wait'
        @call 'ryba/hadoop/mapred_jhs/wait'
        @call
          unless_exec: mkcmd.hdfs @, "yarn --config #{@config.ryba.yarn.rm.conf_dir} rmadmin -getServiceState #{@config.shortname} | grep 'active'"
          handler: ->      
            @execute
              cmd: """
                hdp-select hadoop-yarn-resourcemanager 2.4.0.0-169
                service hadoop-yarn-resourcemanager restart
              """
    
    exports.push
      header: 'Upgrade active ResourceManager'
      if: -> @has_module 'ryba/hadoop/yarn_rm'
      handler: ->
        @call 'ryba/hadoop/yarn_ts/wait'
        @call 'ryba/hadoop/mapred_jhs/wait'
        @call 'ryba/hadoop/yarn_rm/wait'
        @execute
          cmd: """
          hdp-select hadoop-yarn-resourcemanager 2.4.0.0-169
          service hadoop-yarn-resourcemanager restart
          """
        @call 'ryba/hadoop/yarn_rm/wait'
        @call (_, callback) ->
          setTimeout callback, 20000

    exports.push
      header: 'Upgrade NodeManager'
      if: -> @has_module 'ryba/hadoop/yarn_nm'
      handler: ->
        @register 'hdp_select', 'ryba/lib/hdp_select'
        @hdp_select
          name: 'hadoop-yarn-nodemanager'
        @call 'ryba/hadoop/yarn_nm/stop'
        @call 'ryba/hadoop/yarn_nm/start'
        @call (_, callback) ->
          setTimeout callback, 60000   

    exports.push
      header: 'Configure Yarn TS'
      if: -> @has_module 'ryba/hadoop/yarn_ts'
      handler: ->
        @call 'ryba/hadoop/yarn_ts/install'
        @call 'ryba/hadoop/yarn_ts/stop'
        @call 'ryba/hadoop/yarn_ts/start'
        @call 'ryba/hadoop/yarn_ts/wait'

    exports.push
      header: 'Configure Mapred JHS'
      if: -> @has_module 'ryba/hadoop/mapred_jhs'
      handler: ->
        @call 'ryba/hadoop/mapred_jhs/install'
        @call 'ryba/hadoop/mapred_jhs/stop'
        @call 'ryba/hadoop/mapred_jhs/start'

    exports.push
      header: 'Configure standby ResourceManager'
      if: -> @has_module 'ryba/hadoop/yarn_rm'
      handler: ->
        @call 'ryba/hadoop/yarn_ts/wait'
        @call 'ryba/hadoop/mapred_jhs/wait'
        @call
          unless_exec: mkcmd.hdfs @, "yarn --config #{@config.ryba.yarn.rm.conf_dir} rmadmin -getServiceState #{@config.shortname} | grep 'active'"
          handler: ->      
            @call 'ryba/hadoop/yarn_rm/install'
            @call 'ryba/hadoop/yarn_rm/stop'
            @call 'ryba/hadoop/yarn_rm/start'
            
    exports.push
      header: 'Configure active ResourceManager'
      if: -> @has_module 'ryba/hadoop/yarn_rm'
      handler: ->
        @call
          if_exec: mkcmd.hdfs @, "yarn --config #{@config.ryba.yarn.rm.conf_dir} rmadmin -getServiceState #{@config.shortname} | grep 'active'"
          handler: ->      
            @call 'ryba/hadoop/yarn_rm/install'
            @call 'ryba/hadoop/yarn_rm/stop'
            @call 'ryba/hadoop/yarn_rm/start'

    exports.push
      header: 'Configure Yarn NodeManager'
      if: -> @has_module 'ryba/hadoop/yarn_nm'
      handler: ->
        @call 'ryba/hadoop/yarn_nm/install'
        @call 'ryba/hadoop/yarn_nm/stop'
        @call 'ryba/hadoop/yarn_nm/start'
        @call (_, callback) ->
          setTimeout callback, 30000

    exports.push
      header: 'Wait YARN Services Start'
      handler: ->
        @call 'ryba/hadoop/yarn_ts/wait'
        @call 'ryba/hadoop/mapred_jhs/wait'
        @call 'ryba/hadoop/yarn_rm/wait'
        @call 'ryba/hadoop/yarn_nm/wait'  

## Dependencies

    util = require 'util'
    each = require 'each'
    {merge} = require 'mecano/lib/misc'
    run = require 'masson/lib/run'
    mkcmd = require '../mkcmd'
    # parse_jdbc = require '../parse_jdbc'
