
# HBase


Use [Apache HBase™](http://hbase.apache.org/) when you need random, realtime read/write access to your Big Data.
This project's goal is the hosting of very large tables database - atop clusters of commodity hardware.
Apache HBase is an open-source, distributed, versioned, non-relational database modeled after Google's Bigtable: A Distributed Storage System for Structured Data by Chang et al. Just as Bigtable leverages the distributed data storage provided by the Google File System,
Apache HBase provides Bigtable-like capabilities on top of Hadoop and HDFS

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push require '../lib/hdp_select'

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

    module.exports.configure = (ctx) ->
      if ctx.hbase_configured then return else ctx.hbase_configured = null
      require('masson/commons/java').configure ctx
      {java_home} = ctx.config.java
      {ryba} = ctx.config
      {static_host, realm} = ryba
      zk_hosts = ctx.hosts_with_module('ryba/zookeeper/server').join ','
      zk_port = ctx.contexts 'ryba/zookeeper/server', require('../zookeeper/server').configure
      zk_port = zk_port[0].config.ryba.zookeeper.port
      # User
      hbase = ryba.hbase ?= {}
      hbase.user ?= {}
      hbase.user = name: ryba.hbase.user if typeof ryba.hbase.user is 'string'
      hbase.user.name ?= 'hbase'
      hbase.user.system ?= true
      hbase.user.comment ?= 'HBase User'
      hbase.user.home ?= '/var/run/hbase'
      hbase.user.groups ?= 'hadoop'
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
      hbase.pid_dir ?= '/var/run/hbase'
      # Configuration
      hbase.site ?= {}
      hbase.site['zookeeper.znode.parent'] ?= '/hbase'
      # The mode the cluster will be in. Possible values are
      # false: standalone and pseudo-distributed setups with managed Zookeeper
      # true: fully-distributed with unmanaged Zookeeper Quorum (see hbase-env.sh)
      hbase.site['hbase.cluster.distributed'] = 'true'
      # Enter the HBase NameNode server hostname
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-High-Availability-Guide/cdh4hag_topic_2_6.html
      nn_host = unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      then ctx.host_with_module 'ryba/hadoop/hdfs_nn'
      else ryba.nameservice
      hbase.site['hbase.rootdir'] ?= "hdfs://#{nn_host}:8020/apps/hbase/data"
      # Comma separated list of Zookeeper servers (match to
      # what is specified in zoo.cfg but without portnumbers)
      hbase.site['hbase.zookeeper.quorum'] = "#{zk_hosts}"
      hbase.site['hbase.zookeeper.property.clientPort'] = "#{zk_port}"
      # Short-circuit are true but socket.path isnt defined for hbase, only for hdfs, see http://osdir.com/ml/hbase-user-hadoop-apache/2013-03/msg00007.html
      # hbase.site['dfs.domain.socket.path'] ?= hdfs.site['dfs.domain.socket.path']
      hbase.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'


## Configuration for Security

Bulk loading in secure mode is a bit more involved than normal setup, since the
client has to transfer the ownership of the files generated from the mapreduce
job to HBase. Secure bulk loading is implemented by a coprocessor, named
[SecureBulkLoadEndpoint] and use an HDFS directory which is world traversable
(-rwx--x--x, 711).

      hbase.site['hbase.security.authentication'] ?= 'kerberos' # Required by HM, RS and client
      hbase.site['hbase.security.authorization'] ?= 'true'
      hbase.site['hbase.rpc.engine'] ?= 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
      hbase.site['hbase.superuser'] ?= hbase.admin.name
      hbase.site['hbase.bulkload.staging.dir'] ?= '/apps/hbase/staging'
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
      hbase.env ?=  {}
      hbase.env['JAVA_HOME'] ?= "#{java_home}"
      hbase.env['HBASE_LOG_DIR'] ?= "#{hbase.log_dir}"
      hbase.env['HBASE_OPTS'] ?= if ctx.has_module 'ryba/hbase/client'
      then "-ea -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -Djava.security.auth.login.config=#{hbase.conf_dir}/hbase-client.jaas"
      else '-ea -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode' # Default in HDP companion file
      hbase.env['HBASE_MASTER_OPTS'] ?= if ctx.has_module 'ryba/hbase/master'
      then "-Xmx2048m -Djava.security.auth.login.config=#{hbase.conf_dir}/hbase-master.jaas"
      else '-Xmx2048m' # Default in HDP companion file
      hbase.env['HBASE_REGIONSERVER_OPTS'] ?= if ctx.has_module 'ryba/hbase/regionserver'
      then "-Xmn200m -Xms4096m -Xmx4096m -Djava.security.auth.login.config=#{hbase.conf_dir}/hbase-regionserver.jaas"
      else '-Xmn200m -Xms4096m -Xmx4096m' # Default in HDP companion file
      require('../hadoop/core').configure ctx

## Configuration for High Availability (HA)

*   [Hortonworks presentation of HBase HA][ha-next-level]
*   [HDP 2.3 Read HA instruction][hdp23]
*   [Bring quorum based write ahead log (write HA)][HBASE-12259]

[ha-next-level]: http://hortonworks.com/blog/apache-hbase-high-availability-next-level/
[hdp23]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.0/bk_hadoop-ha/content/ch_HA-HBase.html
[HBASE-12259]: https://issues.apache.org/jira/browse/HBASE-12259

      if ctx.contexts('ryba/hbase/master').length > 1 # HA enabled
        if ctx.has_any_modules 'ryba/hbase/master', 'ryba/hbase/regionserver'
          # StoreFile Refresher
          hbase.site['hbase.regionserver.storefile.refresh.all'] ?= 'true'
          # Store File TTL
          hbase.site['hbase.regionserver.storefile.refresh.period'] ?= '30000' # Default to '0'
          # Async WAL Replication
          hbase.site['hbase.region.replica.replication.enabled'] ?= 'true'
          hbase.site['hbase.regionserver.storefile.refresh.all'] ?= 'false'
          # Store File TTL
          hbase.site['hbase.master.hfilecleaner.ttl'] ?= '3600000' # 1 hour
          hbase.site['hbase.master.loadbalancer.class'] ?= 'org.apache.hadoop.hbase.master.balancer.StochasticLoadBalancer' # Default value
          hbase.site['hbase.meta.replica.count'] ?= '3' # Default to '1'
          hbase.site['hbase.region.replica.wait.for.primary.flush'] ?= 'true'
          hbase.site['hbase.region.replica.storefile.refresh.memstore.multiplier'] ?= '4'
        if ctx.has_any_modules 'ryba/hbase/client'
          hbase.site['hbase.ipc.client.specificThreadForWriting'] ?= 'true'
          hbase.site['hbase.client.primaryCallTimeout.get'] ?= '10000'
          hbase.site['hbase.client.primaryCallTimeout. multiget'] ?= '10000'
          hbase.site['hbase.client.primaryCallTimeout.scan'] ?= '1000000'
          hbase.site['hbase.meta.replicas.use'] ?= 'true'

## Users & Groups

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
hbase:x:492:492:HBase:/var/run/hbase:/bin/bash
cat /etc/group | grep hbase
hbase:x:492:
```

    module.exports.push name: 'HBase # Users & Groups', handler: ->
      {hbase} = @config.ryba
      @group hbase.group
      @user hbase.user

## Install

Instructions to [install the HBase RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap9-1.html)

    module.exports.push name: 'HBase # Install', timeout: -1, handler: ->
      @service
        name: 'hbase'
      @hdp_select
        name: 'hbase-client'

    module.exports.push name: 'HBase # Layout', timeout: -1, handler: ->
      {hbase} = @config.ryba
      @mkdir
        destination: hbase.pid_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755
      @mkdir
        destination: hbase.log_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755

    module.exports.push name: 'HBase # Env', handler: ->
      {hbase} = @config.ryba
      write = for k, v of hbase.env
        match: RegExp "export #{k}=.*", 'm'
        replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
      # Fix mapreduce looking for "mapreduce.tar.gz"
      write.push
        match: /^export HBASE_OPTS=".*" # RYBA HDP VERSION$/m
        replace: "export HBASE_OPTS=\"-Dhdp.version=$HDP_VERSION $HBASE_OPTS\" # RYBA HDP VERSION"
        append: true
      @upload
        source: "#{__dirname}/../resources/hbase/hbase-env.sh"
        destination: "#{hbase.conf_dir}/hbase-env.sh"
        write: write
        backup: true
        eof: true

## RegionServers

Upload the list of registered RegionServers.

    module.exports.push name: 'HBase # RegionServers', handler: ->
      {hbase, hadoop_group} = @config.ryba
      @write
        content: @hosts_with_module('ryba/hbase/regionserver').join '\n'
        destination: "#{hbase.conf_dir}/regionservers"
        uid: hbase.user.name
        gid: hadoop_group.name
        eof: true
        if: !!@has_any_modules ['ryba/hbase/master', 'ryba/hbase/regionserver']

## Resources

*   [HBase: Performance Tunners (read optimization)](http://labs.ericsson.com/blog/hbase-performance-tuners)
*   [Scanning in HBase (read optimization)](http://hadoop-hbase.blogspot.com/2012/01/scanning-in-hbase.html)
*   [Configuring HBase Memstore (write optimization)](http://blog.sematext.com/2012/17/16/hbase-memstore-what-you-should-know/)
*   [Visualizing HBase Flushes and Compactions (write optimization)](http://www.ngdata.com/visiualizing-hbase-flushes-and-compactions/)

[SecureBulkLoadEndpoint]: http://hbase.apache.org/apidocs/org/apache/hadoop/hbase/security/access/SecureBulkLoadEndpoint.html
