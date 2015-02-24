
# Hadoop HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things
like the directory tree, file permissions, and the mapping of files to block
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It
does not store the data of these files itself. It’s important that this metadata
(and all changes to it) are safely persisted to stable storage for fault tolerance.

    module.exports = []

## Configuration

Look at the file [DFSConfigKeys.java][keys] for an exhaustive list of supported
properties.

*   `ryba.hdfs.site` (object)   
    Properties added to the "hdfs-site.xml" file.   
*   `ryba.hdfs.namenode_opts` (string)   
    NameNode options.   

Example:   

```json
{
  "ryba": {
    "hdfs": {
      "namenode_opts": "-Xms1024m -Xmx1024m"
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./hdfs').configure ctx
      {ryba} = ctx.config
      throw Error "Missing \"ryba.zkfc_password\" property" unless ryba.zkfc_password
      # Data
      # Comma separated list of paths. Use the list of directories.
      # For example, /data/1/hdfs/nn,/data/2/hdfs/nn.
      ryba.hdfs.site['dfs.namenode.name.dir'] ?= ['/var/hdfs/name']
      ryba.hdfs.site['dfs.namenode.name.dir'] = ryba.hdfs.site['dfs.namenode.name.dir'].join ',' if Array.isArray ryba.hdfs.site['dfs.namenode.name.dir']
      # Activate ACLs
      ryba.hdfs.site['dfs.namenode.acls.enabled'] ?= 'true'
      ryba.hdfs.site['dfs.namenode.accesstime.precision'] ?= null
      ryba.hdfs.site['dfs.ha.automatic-failover.enabled'] ?= 'true'
      ryba.hdfs.namenode_opts ?= null

## Configuration for HDFS High Availability (HA)

Add High Availability specific properties to the "hdfs-site.xml" file. The
inserted properties are similar than the ones for a client or slave
configuration with the additionnal "dfs.namenode.shared.edits.dir" property.

The default configuration implement the "sshfence" fencing method. This method
SSHes to the target node and uses fuser to kill the process listening on the
service's TCP port.

      if ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        journalnodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
        ryba.hdfs.site['dfs.namenode.shared.edits.dir'] = (for jn in journalnodes then "#{jn}:8485").join ';'
        ryba.hdfs.site['dfs.namenode.shared.edits.dir'] = "qjournal://#{ryba.hdfs.site['dfs.namenode.shared.edits.dir']}/#{ryba.hdfs.site['dfs.nameservices']}"
        # Fencing
        ryba.hdfs.site['dfs.ha.fencing.methods'] ?= "sshfence(#{ryba.hdfs.user.name})"
        ryba.hdfs.site['dfs.ha.fencing.ssh.private-key-files'] ?= "#{ryba.hdfs.user.home}/.ssh/id_rsa"

## Commands

    module.exports.push commands: 'backup', modules: 'ryba/hadoop/hdfs_nn_backup'

    module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_nn_check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/hdfs_nn_install'
      'ryba/hadoop/hdfs_nn_start'
      'ryba/hadoop/hdfs_nn_check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/hdfs_nn_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/hdfs_nn_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/hdfs_nn_stop'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java


