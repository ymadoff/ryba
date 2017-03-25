
## Configuration

The module extends the various settings set by the "ryba/hadoop/hdfs" module.

Unless specified otherwise, the number of tolerated failed volumes is set to "1"
if at least 4 disks are used for storage.

*   `ryba.hdfs.dn.java_opts` (string)
    Datanode Java options.

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

    module.exports = ->
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

## Centralized Cache Management

Centralized cache management in HDFS is an explicit caching mechanism that enables you to specify paths to directories or files that will be cached by HDFS.

If you get the error "Cannot start datanode because the configured max locked 
memory size... is more than the datanode's available RLIMIT_MEMLOCK ulimit," 
that means that the operating system is imposing a lower limit on the amount of 
memory that you can lock than what you have configured.

## Kerberos

      ryba.hdfs.site['dfs.datanode.kerberos.principal'] ?= "dn/_HOST@#{ryba.realm}"
      ryba.hdfs.site['dfs.datanode.keytab.file'] ?= '/etc/security/keytabs/dn.service.keytab'

## Tuning

      dataDirs = ryba.hdfs.site['dfs.datanode.data.dir'].split(',')
      if dataDirs.length > 3
        ryba.hdfs.site['dfs.datanode.failed.volumes.tolerated'] ?= '1'
      else
        ryba.hdfs.site['dfs.datanode.failed.volumes.tolerated'] ?= '0'
      # Validation
      if ryba.hdfs.site['dfs.datanode.failed.volumes.tolerated'] >= dataDirs.length
        throw Error 'Number of failed volumes must be less than total volumes'
      ryba.hdfs.datanode_opts ?= ''

## Storage-Balancing Policy

      # http://gbif.blogspot.fr/2015/05/dont-fill-your-hdfs-disks-upgrading-to.html
      # http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_dn_storage_balancing.html
      ryba.hdfs.site['dfs.datanode.fsdataset.volume.choosing.policy'] ?= 'org.apache.hadoop.hdfs.server.datanode.fsdataset.AvailableSpaceVolumeChoosingPolicy'
      ryba.hdfs.site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-threshold'] ?= '10737418240' # 10GB
      ryba.hdfs.site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction'] ?= '1.0'
      # Note, maybe do a better estimation of du.reserved inside capacity
      # currently, 50GB throw DataXceiver exception inside vagrant vm
      ryba.hdfs.site['dfs.datanode.du.reserved'] ?= '1073741824' # 1GB, also default in ambari

## HDFS Balancer Performance increase (Fast Mode)

      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_hdfs-administration/content/configuring_balancer.html
      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_hdfs-administration/content/recommended_configurations.html
      ryba.hdfs.site['dfs.datanode.balance.max.concurrent.moves'] ?=  Math.max 5, dataDirs.length * 4
      ryba.hdfs.site['dfs.datanode.balance.bandwidthPerSec'] ?= 10737418240 #(10 GB/s) default is 1048576 (=1MB/s)

## Env

Set up jave heap size linke in `ryba/hadoop/hdfs_nn`.

      ryba.hdfs.dn ?= {}
      ryba.hdfs.dn.opts ?= {}
      ryba.hdfs.dn.java_opts ?= ''
      ryba.hdfs.dn.newsize ?= '200m'
      ryba.hdfs.dn.heapsize ?= '1024m'

## HDFS Short-Circuit Local Reads

[Short Circuit] need to be configured on the DataNode and the client.

[Short Circuit]: https://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html

      ryba.hdfs.site['dfs.client.read.shortcircuit'] ?= if @has_service 'ryba/hadoop/hdfs_dn' then 'true' else 'false'
      ryba.hdfs.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

## Configuration for Log4J

      ryba.hdfs.dn.log4j ?= {}
      ryba.hdfs.dn.root_logger ?= 'INFO,RFA'
      ryba.hdfs.dn.security_logger ?= 'INFO,RFAS'
      ryba.hdfs.dn.audit_logger ?= 'INFO,RFAAUDIT'
      if @config.log4j?.services?
        if @config.log4j?.remote_host? && @config.log4j?.remote_port? && ('ryba/hadoop/hdfs_dn' in @config.log4j.services)
          # Root logger
          if ryba.hdfs.dn.root_logger.indexOf(ryba.hdfs.dn.socket_client) is -1
          then ryba.hdfs.dn.root_logger += ",#{ryba.hdfs.dn.socket_client}"
          # Security Logger
          if ryba.hdfs.dn.security_logger.indexOf(ryba.hdfs.dn.socket_client) is -1
          then ryba.hdfs.dn.security_logger += ",#{ryba.hdfs.dn.socket_client}"
          # Audit Logger
          if ryba.hdfs.dn.audit_logger.indexOf(ryba.hdfs.dn.socket_client) is -1
          then ryba.hdfs.dn.audit_logger += ",#{ryba.hdfs.dn.socket_client}"
          # adding SOCKET appender
          ryba.hdfs.dn.socket_client ?= "SOCKET"
          # Adding Application name, remote host and port values in namenode's opts
          ryba.hdfs.dn.opts['hadoop.log.application'] ?= 'namenode'
          ryba.hdfs.dn.opts['hadoop.log.remote_host'] ?= @config.log4j.remote_host
          ryba.hdfs.dn.opts['hadoop.log.remote_port'] ?= @config.log4j.remote_port

          ryba.hdfs.dn.socket_opts ?=
            Application: '${hadoop.log.application}'
            RemoteHost: '${hadoop.log.remote_host}'
            Port: '${hadoop.log.remote_port}'
            ReconnectionDelay: '10000'

          ryba.hdfs.dn.log4j = merge ryba.hdfs.dn.log4j, appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: ryba.hdfs.dn.socket_client
            logj4: ryba.hdfs.dn.log4j
            properties: ryba.hdfs.dn.socket_opts

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'
