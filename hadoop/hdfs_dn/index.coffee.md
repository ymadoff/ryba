
# Hadoop HDFS DataNode

A [DataNode](http://wiki.apache.org/hadoop/DataNode) manages the storage attached to the node it run on. There are usually
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

The module extends the various settings set by the "ryba/hadoop/hdfs" module.

Unless specified otherwise, the number of tolerated failed volumes is set to "1"
if at least 4 disks are used for storage.

*   `ryba.hdfs.datanode_opts` (string)
    NameNode options.

Example:

```json
{
  "ryba": {
    "hdfs": {
      "datanode_opts": "-Xmx1024m",
      "sysctl": {
        "vm.swappiness": 0,
        "vm.overcommit_memory": 1,
        "vm.overcommit_ratio": 100,
        "net.core.somaxconn": 1024
    }
  }
}
```

    module.exports.configure = (ctx) ->
      if ctx.hdfs_dn_configured then return else ctx.hdfs_dn_configured = true
      require('masson/core/iptables').configure ctx
      require('../hdfs').configure ctx
      {ryba} = ctx.config
      ryba.hdfs ?= {}
      ryba.hdfs.sysctl ?= {}
      require('../hdfs_nn').client_config ctx
      # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.
      # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
      ryba.hdfs.site['dfs.datanode.data.dir'] ?= ['file:///var/hdfs/data']
      ryba.hdfs.site['dfs.datanode.data.dir'] = ryba.hdfs.site['dfs.datanode.data.dir'].join ',' if Array.isArray ryba.hdfs.site['dfs.datanode.data.dir']
      # ctx.config.ryba.hdfs.site['dfs.datanode.data.dir.perm'] ?= '750'
      ryba.hdfs.site['dfs.datanode.data.dir.perm'] ?= '700'
      if ryba.core_site['hadoop.security.authentication'] is 'kerberos'
        # Default values are retrieved from the official HDFS page called
        # ["SecureMode"][hdfs_secure].
        # Ports must be below 1024, because this provides part of the security
        # mechanism to make it impossible for a user to run a map task which
        # impersonates a DataNode
        # TODO: Move this to 'ryba/hadoop/hdfs_dn'
        ryba.hdfs.site['dfs.datanode.address'] ?= '0.0.0.0:1004'
        ryba.hdfs.site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        ryba.hdfs.site['dfs.datanode.http.address'] ?= '0.0.0.0:1006'
        ryba.hdfs.site['dfs.datanode.https.address'] ?= '0.0.0.0:50475'
      else
        ryba.hdfs.site['dfs.datanode.address'] ?= '0.0.0.0:50010'
        ryba.hdfs.site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        ryba.hdfs.site['dfs.datanode.http.address'] ?= '0.0.0.0:50075'
        ryba.hdfs.site['dfs.datanode.https.address'] ?= '0.0.0.0:50475'
      # Kerberos
      ryba.hdfs.site['dfs.datanode.kerberos.principal'] ?= "dn/#{ryba.static_host}@#{ryba.realm}"
      ryba.hdfs.site['dfs.datanode.keytab.file'] ?= '/etc/security/keytabs/dn.service.keytab'
      # Tuning
      dataDirs = ryba.hdfs.site['dfs.datanode.data.dir'].split(',')
      if dataDirs.length > 3
        ryba.hdfs.site['dfs.datanode.failed.volumes.tolerated'] ?= '1'
      else
        ryba.hdfs.site['dfs.datanode.failed.volumes.tolerated'] ?= '0'
      # Validation
      if ryba.hdfs.site['dfs.datanode.failed.volumes.tolerated'] >= dataDirs.length
        throw Error 'Number of failed volumes must be less than total volumes'
      ryba.hdfs.datanode_opts ?= ''
      # look at
      # http://gbif.blogspot.fr/2015/05/dont-fill-your-hdfs-disks-upgrading-to.html
      # dfs.datanode.du.reserved:25GB
      # dfs.datanode.fsdataset.volume.choosing.policy:AvailableSpace 
      # dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction:1.0 

    module.exports.client_config = (ctx) ->
      {ryba} = ctx.config
      # Import properties from DataNode
      [dn_ctx] = ctx.contexts 'ryba/hadoop/hdfs_dn', module.exports.configure
      properties = [
        'dfs.datanode.kerberos.principal'
      ]
      for property in properties
        ryba.hdfs.site[property] ?= dn_ctx.config.ryba.hdfs.site[property]

## Commands

    # module.exports.push command: 'backup', modules: 'ryba/hadoop/hdfs_dn_backup'

    module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_dn/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/hdfs_dn/install'
      'ryba/hadoop/hdfs_dn/start'
      'ryba/hadoop/hdfs_dn/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/hdfs_dn/start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/hdfs_dn/status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/hdfs_dn/stop'
