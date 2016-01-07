
# Hue Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    module.exports.push 'ryba/hbase/thrift/wait'
    module.exports.push 'ryba/oozie/server/wait'
    module.exports.push 'ryba/hive/server2/wait'
    module.exports.push 'ryba/hive/hcatalog/wait'


## Start Server

Start the Hue 'hue_server' container as a service. It ensures that docker is running and start hue_server container.
You can start the server manually with the following
command:

```
service hue-server-docker start
```

    module.exports.push header: 'Hue Docker # Start', label_true: 'STARTED', timeout: -1, handler: ->
      {hue_docker} = @config.ryba
      @service_start
        name: hue_docker.service
