---
title: HDFS DataNode
module: ryba/hadoop/hdfs_dn
layout: module
---

# HDFS DataNode

A DataNode manages the storage attached to the node it run on. There are usually
one DataNode per node in the cluster. HDFS exposes a file system namespace and
allows user data to be stored in files. Internally, a file is split into one or
more blocks and these blocks are stored in a set of DataNodes. The DataNodes
also perform block creation, deletion, and replication upon instruction from the
NameNode.

To provide a fast failover in a Higth Availabity (HA) enrironment, it is
necessary that the Standby node have up-to-date information regarding the
location of blocks in the cluster. In order to achieve this, the DataNodes are
configured with the location of both NameNodes, and send block location
information and heartbeats to both.

    module.exports = []

## Configuration

The module doesn't require any configuration but instread rely on the 
"ryba/hadoop/hdfs" configuration settings.

Unless specified otherwise, the number of tolerated failed volumes is set to "1"
if at least 4 disks are used for storage.

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./hdfs').configure ctx
      {hdfs_site} = ctx.config.ryba
      # Tuning
      if hdfs_site['dfs.datanode.data.dir'].length > 3
        hdfs_site['dfs.datanode.failed.volumes.tolerated'] ?= 1
      # Validation
      if hdfs_site['dfs.datanode.failed.volumes.tolerated'] >= hdfs_site['dfs.datanode.data.dir'].length
        throw Error 'Number of failed volumes must be less than total volumes'

    # module.exports.push command: 'backup', modules: 'ryba/hadoop/hdfs_dn_backup'

    module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_dn_check'

    module.exports.push commands: 'install', modules: 'ryba/hadoop/hdfs_dn_install'

    module.exports.push commands: 'start', modules: 'ryba/hadoop/hdfs_dn_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/hdfs_dn_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/hdfs_dn_stop'


