
# Hue Start
    
    module.exports = header: 'Hue Docker Start', label_true: 'STARTED', timeout: -1, handler: ->
      {hue_docker} = @config.ryba
      
## Wait

      @call once: true, 'ryba/hadoop/yarn_rm/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/hbase/thrift/wait'
      @call once: true, 'ryba/oozie/server/wait'
      @call once: true, 'ryba/hive/server2/wait'
      @call once: true, 'ryba/hive/hcatalog/wait'

## Start

Start the Hue 'hue_server' container as a service. It ensures that docker is running and start hue_server container.
You can start the server manually with the following
command:

```
service hue-server-docker start
```

      @service_start
        name: hue_docker.service
