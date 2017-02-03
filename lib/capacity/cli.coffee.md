
# Capacity Planning for Hadoop Cluster

## Main Entry Point

    module.exports = ->
      # Parameters and Help
      params = parameters(exports.params)
      if params.parse().help
        return console.log params.help()
      # Run
      params = params.parse()
      config params.config, (err, config) ->
        throw err if err
        capacity params, config, (err) ->
          if err
            if err.errors
              for err of err.errors
                console.log(err.stack||err.message);
            else
              console.log(err.stack)

## Parameters

*   `config` (array|string)   
    One or multiple configuration files and directories.   
*   `total_memory` (int|string)   
    Total Memory available on the server.   
*   `memory_system` (int|string)   
    Total Memory allocated to the system.   
*   `memory_hbase` (int|string)   
    Total Memory allocated to the HBase RegionServers.   
*   `memory_yarn` (int|string)   
    Total Memory allocated to the Yarn NodeManagers.   
*   `cores` (int)   
    Number of available cores to the Yarn NodeManagers.   
*   `disks` (array)   
    List of disk partitions available to the HDFS DataNodes and YARN NodeManagers.   
*   `module` (String|Array)   
    List of target services based on ryba available modules   

```bash
node node_modules/ryba/bin/capacity \
  -c ./conf \
  --partitions /data/1,/data/2 \
  -o ./conf/capacity.coffee -w
```

    exports.params = 
      name: 'capacity'
      description: 'Hadoop Tool for Capacity Planning'
      options: [
        name: 'config', shortcut: 'c', type: 'array'
        description: 'One or multiple configuration files.'
        required: true
      ,
        name: 'hosts', shortcut: 'h', type: 'array'
        description: 'Limit to a list of server hostnames'
      ,
        name: 'modules', shortcut: 'm', type: 'array'
        description: 'Limit to a list of modules'
      ,
        name: 'output', shortcut: 'o'
        description: 'Write the configuration to a file, extension is discoverd unless "format" is provided.'
      ,
        name: 'format', shortcut: 'f' # default: 'text'
        description: 'Output format are text (default), xml, json, js and coffee.'
      ,
        name: 'overwrite', shortcut: 'w', type: 'boolean' # default: 'text'
        description: 'Overwrite any existing file.'
      ,
        name: 'partitions', shortcut: 'p', type: 'array'
        description: 'List of disk partitions unless discovered.'
      ,
        name: 'hdfs_nn_name_dir' # default: './hdfs/name'
        description: 'Absolute path to a single directory or relative path to the HDFS NameNode directories.'
      ,
        name: 'hdfs_dn_data_dir' # default: './hdfs/data', eg '/mydata/1/hdfs/dn,/mydata/2/hdfs/dn'
        description: 'List of absolute paths or a relative path for HDFS DataNode directories.'
      ,
        name: 'yarn_nm_local_dir' # default: './yarn/local', eg '/mydata/1/yarn/local,/mydata/2/yarn/local'
        description: 'List of absolute paths or a relative path for YARN NodeManager directories.'
      ,
        name: 'yarn_nm_log_dir' # default: './yarn/log', eg '/mydata/1/yarn/log,/mydata/2/yarn/log'
        description: 'List of absolute paths or a relative path for YARN NodeManager directories.'
      ,
        name: 'kafka_data_dir' # default: './kafka', eg '/mydata/1/kafka,/mydata/2/kafka'
        description: 'List of absolute paths or a relative path for Kafka Broker directories.'
      ]

## Dependencies

    parameters = require 'parameters'
    config = require 'masson/lib/config'
    capacity = require './'
