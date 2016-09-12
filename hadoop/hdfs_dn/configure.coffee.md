
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

    module.exports = handler: ->
      {ryba} = @config
      ryba.hdfs ?= {}
      ryba.hdfs.dn ?= {}
      ryba.hdfs.dn.conf_dir ?= '/etc/hadoop-hdfs-datanode/conf'
      ryba.hdfs.sysctl ?= {}
      # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.
      # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
      ryba.hdfs.site['dfs.http.policy'] ?= 'HTTPS_ONLY'
      ryba.hdfs.site['dfs.datanode.data.dir'] ?= ['file:///var/hdfs/data']
      ryba.hdfs.site['dfs.datanode.data.dir'] = ryba.hdfs.site['dfs.datanode.data.dir'].join ',' if Array.isArray ryba.hdfs.site['dfs.datanode.data.dir']
      # @config.ryba.hdfs.site['dfs.datanode.data.dir.perm'] ?= '750'
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
      ryba.hdfs.site['dfs.datanode.kerberos.principal'] ?= "dn/_HOST@#{ryba.realm}"
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
      # Configuring Storage-Balancing for DataNodes
      # http://gbif.blogspot.fr/2015/05/dont-fill-your-hdfs-disks-upgrading-to.html
      # http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_dn_storage_balancing.html
      ryba.hdfs.site['dfs.datanode.fsdataset.volume.choosing.policy'] ?= 'org.apache.hadoop.hdfs.server.datanode.fsdataset.AvailableSpaceVolumeChoosingPolicy'
      ryba.hdfs.site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-threshold'] ?= '10737418240' # 10GB
      ryba.hdfs.site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction'] ?= '1.0'
      # Note, maybe do a better estimation of du.reserved inside capacity
      # currently, 50GB throw DataXceiver exception inside vagrant vm
      ryba.hdfs.site['dfs.datanode.du.reserved'] ?= '1073741824' # 1GB, also default in ambari
      # dfs.datanode.fsdataset.volume.choosing.policy:AvailableSpace 
      # dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction:1.0

## Env
Set up jave heap size linke in `ryba/hadoop/hdfs_nn`.

      ryba.hdfs.dn ?= {}
      ryba.hdfs.datanode_opts ?= ''
      ryba.hdfs.dn.newsize ?= '200m'
      ryba.hdfs.dn.heapsize ?= '1024m'

## HDFS Short-Circuit Local Reads

[Short Circuit] need to be configured on the DataNode and the client.

[Short Circuit]: https://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html

      ryba.hdfs.site['dfs.client.read.shortcircuit'] ?= if @has_module 'ryba/hadoop/hdfs_dn' then 'true' else 'false'
      ryba.hdfs.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'
