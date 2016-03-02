# HBase


Use [Apache HBase™](http://hbase.apache.org/) when you need random, realtime read/write access to your Big Data.
This project's goal is the hosting of very large tables database - atop clusters of commodity hardware.
Apache HBase is an open-source, distributed, versioned, non-relational database modeled after Google's Bigtable: A Distributed Storage System for Structured Data by Chang et al. Just as Bigtable leverages the distributed data storage provided by the Google File System,
Apache HBase provides Bigtable-like capabilities on top of Hadoop and HDFS

## Configure

*   `hbase.user` (object|string)
    The Unix HBase login name or a user object (see Mecano User documentation).
*   `hbase.group` (object|string)
    The Unix HBase group name or a group object (see Mecano Group documentation).

Example

```json
    "hbase":{
      "user": {
        "name": "hbase", "system": true, "gid": "hbase",
        "comment": "HBase User", "home": "/var/run/hbase"
      },
      "group": {
        "name": "HBase", "system": true
      }
    }
```

    module.exports = handler: ->
      # if ctx.hbase_configured then return else ctx.hbase_configured = null
      # require('masson/commons/java').configure ctx
      {java_home} = @config.java
      {ryba} = @config
      {static_host, realm} = ryba
      hbase = ryba.hbase ?= {}
      
# Users & Groups

      hbase.test ?= {}
      hbase.test.default_table ?= 'ryba'
      hbase.user ?= {}
      hbase.user = name: ryba.hbase.user if typeof ryba.hbase.user is 'string'
      hbase.user.name ?= 'hbase'
      hbase.user.system ?= true
      hbase.user.comment ?= 'HBase User'
      hbase.user.home ?= '/var/run/hbase'
      hbase.user.groups ?= 'hadoop'
      hbase.user.limits ?= {}
      hbase.user.limits.nofile ?= 64000
      hbase.user.limits.nproc ?= true
      hbase.admin ?= {}
      hbase.admin.name ?= hbase.user.name
      hbase.admin.principal ?= "#{hbase.admin.name}@#{realm}"
      hbase.admin.password ?= "hbase123"
      # Group
      hbase.group ?= {}
      hbase.group = name: hbase.group if typeof hbase.group is 'string'
      hbase.group.name ?= 'hbase'
      hbase.group.system ?= true
      hbase.user.gid = hbase.group.name
      # Layout
      hbase.conf_dir ?= '/etc/hbase/conf'
      hbase.log_dir ?= '/var/log/hbase'
      
# Configuration

      zk_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
      zk_hosts = zk_ctxs.map( (ctx) -> ctx.config.host).join ','
      zk_port = zk_ctxs[0].config.ryba.zookeeper.port
      hbase.site ?= {}
      hbase.site['zookeeper.znode.parent'] ?= '/hbase'
      # The mode the cluster will be in. Possible values are
      # false: standalone and pseudo-distributed setups with managed Zookeeper
      # true: fully-distributed with unmanaged Zookeeper Quorum (see hbase-env.sh)
      hbase.site['hbase.cluster.distributed'] = 'true'
      # Enter the HBase NameNode server hostname
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-High-Availability-Guide/cdh4hag_topic_2_6.html
      nn_ctxs = @contexts('ryba/hadoop/hdfs_nn')
      nn_host = if nn_ctxs.length > 1 then ryba.nameservice else nn_ctxs[0].config.host
      hbase.site['hbase.rootdir'] ?= "hdfs://#{nn_host}:8020/apps/hbase/data"
      # Comma separated list of Zookeeper servers (match to
      # what is specified in zoo.cfg but without portnumbers)
      hbase.site['hbase.zookeeper.quorum'] = "#{zk_hosts}"
      hbase.site['hbase.zookeeper.property.clientPort'] = "#{zk_port}"
      # Short-circuit are true but socket.path isnt defined for hbase, only for hdfs, see http://osdir.com/ml/hbase-user-hadoop-apache/2013-03/msg00007.html
      # hbase.site['dfs.domain.socket.path'] ?= hdfs.site['dfs.domain.socket.path']
      hbase.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'
      
      
## Configuration for Security
            
      hbase.site['hbase.security.authentication'] ?= 'kerberos' # Required by HM, RS and client
      hbase.site['hbase.security.authorization'] ?= 'true'
      hbase.site['hbase.master.kerberos.principal'] ?= "hbase/_HOST@#{realm}" # "hm/_HOST@#{realm}" <-- need zookeeper auth_to_local
      hbase.site['hbase.regionserver.kerberos.principal'] ?= "hbase/_HOST@#{realm}" # "rs/_HOST@#{realm}" <-- need zookeeper auth_to_localw
      hbase.site['hbase.rpc.engine'] ?= 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
      # if ctx.has_module 'ryba/hbase/master'
      # hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.hadoop.hbase.security.access.AccessController'
      # if ctx.has_module 'ryba/hbase/regionserver'
      # hbase.site['hbase.coprocessor.region.classes'] ?= [
      #   'org.apache.hadoop.hbase.security.token.TokenProvider'
      #   'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint'
      #   'org.apache.hadoop.hbase.security.access.AccessController'
      # ]
      # hbase.site['hbase.coprocessor.region.classes'] = hbase.site['hbase.coprocessor.region.classes'].join ',' if Array.isArray hbase.site['hbase.coprocessor.region.classes']
      # hbase.site['hbase.coprocessor.region.classes'] ?= [
      #   'org.apache.hadoop.hbase.security.token.TokenProvider'
      #   'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint'
      #   'org.apache.hadoop.hbase.security.access.AccessController'
      # ]
      # hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.hadoop.hbase.security.access.AccessController'
      # Environment
      # Environment
      hbase.env ?=  {}
      hbase.env['JAVA_HOME'] ?= "#{java_home}"
      hbase.env['HBASE_LOG_DIR'] ?= "#{hbase.log_dir}"
      hbase.env['HBASE_OPTS'] ?= '-ea -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode' # Default in HDP companion file
      hbase.env['HBASE_MASTER_OPTS'] ?= '-Xmx2048m' # Default in HDP companion file
      hbase.env['HBASE_REGIONSERVER_OPTS'] ?= '-Xmn200m -Xms4096m -Xmx4096m' # Default in HDP companion file

      


## Resources

*   [HBase: Performance Tunners (read optimization)](http://labs.ericsson.com/blog/hbase-performance-tuners)
*   [Scanning in HBase (read optimization)](http://hadoop-hbase.blogspot.com/2012/01/scanning-in-hbase.html)
*   [Configuring HBase Memstore (write optimization)](http://blog.sematext.com/2012/17/16/hbase-memstore-what-you-should-know/)
*   [Visualizing HBase Flushes and Compactions (write optimization)](http://www.ngdata.com/visiualizing-hbase-flushes-and-compactions/)

[SecureBulkLoadEndpoint]: http://hbase.apache.org/apidocs/org/apache/hadoop/hbase/security/access/SecureBulkLoadEndpoint.html
