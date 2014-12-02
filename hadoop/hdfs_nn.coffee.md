---
title: HDP HDFS NameNode
module: ryba/hadoop/hdfs_nn
layout: module
---

# HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things
like the directory tree, file permissions, and the mapping of files to block
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It
does not store the data of these files itself. It’s important that this metadata
(and all changes to it) are safely persisted to stable storage for fault tolerance.

    module.exports = []

## Configuration

The NameNode doesn't define new configuration properties. However, it uses properties
define inside the "ryba/hadoop/hdfs" and "masson/core/nc" modules.

*   `namenode_opts` (string)   
    NameNode options.   

Example:   

```json
{
  "ryba": {
    "namenode_opts": "-Xms1024m -Xmx1024m"
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./hdfs').configure ctx
      {ryba} = ctx.config
      throw Error "Missing \"ryba.zkfc_password\" property" unless ryba.zkfc_password
      # Activate ACLs
      ryba.hdfs_site['dfs.namenode.acls.enabled'] ?= 'true'
      ryba.hdfs_site['dfs.namenode.accesstime.precision'] ?= null
      ryba.hdfs_site['dfs.ha.automatic-failover.enabled'] ?= 'true'
      ryba.namenode_opts ?= null

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/hdfs_nn_backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_nn_check'

    module.exports.push commands: 'install', modules: 'ryba/hadoop/hdfs_nn_install'

    module.exports.push commands: 'start', modules: 'ryba/hadoop/hdfs_nn_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/hdfs_nn_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/hdfs_nn_stop'

