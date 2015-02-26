
# Capacity Planning for Hadoop Cluster

## Parameters

*   `config` (array|string)   
    One or multiple configuration files and directories.   
*   `total_memory` (int|string)   
    Total Memory available on the server.   
*   `memory_system` (int|string)   
    Total Memory allocated to the system.   
*   `memory_hbase` (int|string)   
    Total Memory allocated to the Yarn NodeManagers.   
*   `memory_yarn` (int|string)   
    Total Memory allocated to the HBase RegionServers.   
*   `cores` (int)   
    Number of available cores to the Yarn NodeManagers.   
*   `disks` (array)   
    List of disk partitions available to the HDFS DataNodes and YARN NodeManagers.   

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
        description: 'Absolute path to a single directory or relative path to the HDFS NameNode name directories.'
      ,
        name: 'hdfs_dn_data_dir' # default: './hdfs/data'
        description: 'Relative path to the HDFS DataNode local directories.'
      ,
        name: 'yarn_nm_local_dir' # default: './yarn/local'
        description: 'Relative path to the YARN NodeManager local directories.'
      ,
        name: 'yarn_nm_log_dir' # default: './yarn/log'
        description: 'Relative path to the YARN NodeManager local directories.'
      ]

## Dependencies

    parameters = require 'parameters'
    config = require 'masson/lib/config'
    capacity = require './index'
    util = require 'util'

## Main Entry Point

    params = parameters(exports.params)
    if params.parse().help
      return util.print(params.help())

    config params.parse(), (err, config) ->
      capacity config, (err) ->
        if err
          if err.errors
            for err of err.errors
              console.log(err.stack||err.message);
          else
            console.log(err.stack)
