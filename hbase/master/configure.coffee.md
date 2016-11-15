
# HBase Master Configuration

    module.exports = ->
      zk_ctxs = @contexts 'ryba/zookeeper/server'
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      dn_ctxs = @contexts 'ryba/hadoop/hdfs_dn'
      hadoop_ctxs = @contexts ['ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      hbase_ctxs = @contexts 'ryba/hbase/master'
      ryba = @config.ryba ?= {}
      {realm, hbase, ganglia, graphite} = @config.ryba
      {java_home} = @config.java
      hbase = @config.ryba.hbase ?= {}

# Users & Groups

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

      hbase.test ?= {}
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

## Master Configuration

      hbase.master ?= {}
      hbase.master.conf_dir ?= '/etc/hbase-master/conf'
      hbase.master.log_dir ?= '/var/log/hbase'
      hbase.master.pid_dir ?= '/var/run/hbase'
      hbase.master.site ?= {}
      hbase.master.site['hbase.master.port'] ?= '60000'
      hbase.master.site['hbase.master.info.port'] ?= '60010'
      hbase.master.site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
      hbase.master.site['hbase.ssl.enabled'] ?= 'true'
      hbase.master.env ?= {}
      hbase.master.env['JAVA_HOME'] ?= "#{java_home}"
      hbase.master.env['HBASE_LOG_DIR'] ?= "#{hbase.master.log_dir}"
      hbase.master.env['HBASE_OPTS'] ?= '-ea -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode' # Default in HDP companion file

## Configuration Distributed mode

      zk_hosts = zk_ctxs.map( (ctx) -> ctx.config.host).join ','
      zk_port = zk_ctxs[0].config.ryba.zookeeper.port
      hbase.master.site ?= {}
      hbase.master.site['zookeeper.znode.parent'] ?= '/hbase'
      # The mode the cluster will be in. Possible values are
      # false: standalone and pseudo-distributed setups with managed Zookeeper
      # true: fully-distributed with unmanaged Zookeeper Quorum (see hbase-env.sh)
      hbase.master.site['hbase.cluster.distributed'] = 'true'
      # Enter the HBase NameNode server hostname
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-High-Availability-Guide/cdh4hag_topic_2_6.html
      nn_host = if nn_ctxs.length > 1 then ryba.nameservice else nn_ctxs[0].config.host
      hbase.master.site['hbase.rootdir'] ?= "hdfs://#{nn_host}:8020/apps/hbase/data"
      # Comma separated list of Zookeeper servers (match to
      # what is specified in zoo.cfg but without portnumbers)
      hbase.master.site['hbase.zookeeper.quorum'] = "#{zk_hosts}"
      hbase.master.site['hbase.zookeeper.property.clientPort'] = "#{zk_port}"
      # Short-circuit are true but socket.path isnt defined for hbase, only for hdfs, see http://osdir.com/ml/hbase-user-hadoop-apache/2013-03/msg00007.html
      # hbase.master.site['dfs.domain.socket.path'] ?= hdfs.site['dfs.domain.socket.path']
      hbase.master.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

## Configuration for Kerberos

      hbase.master.site['hbase.security.authentication'] ?= 'kerberos' # Required by HM, RS and client
      hbase.master.site['hbase.master.keytab.file'] ?= '/etc/security/keytabs/hm.service.keytab'
      hbase.master.site['hbase.master.kerberos.principal'] ?= "hbase/_HOST@#{realm}" # "hm/_HOST@#{realm}" <-- need zookeeper auth_to_local
      hbase.master.site['hbase.regionserver.kerberos.principal'] ?= "hbase/_HOST@#{realm}" # "rs/_HOST@#{realm}" <-- need zookeeper auth_to_local
      hbase.master.site['hbase.coprocessor.master.classes'] ?= 'org.apache.hadoop.hbase.security.access.AccessController'
      # master be able to communicate with regionserver
      hbase.master.site['hbase.coprocessor.region.classes'] ?= [
        'org.apache.hadoop.hbase.security.token.TokenProvider'
        'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint'
        'org.apache.hadoop.hbase.security.access.AccessController'
      ]

## Configuration for Security

Bulk loading in secure mode is a bit more involved than normal setup, since the
client has to transfer the ownership of the files generated from the mapreduce
job to HBase. Secure bulk loading is implemented by a coprocessor, named
[SecureBulkLoadEndpoint] and use an HDFS directory which is world traversable
(-rwx--x--x, 711).

      hbase.master.site['hbase.security.authorization'] ?= 'true'
      hbase.master.site['hbase.rpc.engine'] ?= 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
      hbase.master.site['hbase.superuser'] ?= hbase.admin.name
      hbase.master.site['hbase.bulkload.staging.dir'] ?= '/apps/hbase/staging'
      hbase.master.opts ?= "-Xmx2048m "
      if hbase.master.opts.indexOf('-Djava.security.auth.login.config') is -1
        hbase.master.opts += " -Djava.security.auth.login.config=#{hbase.master.conf_dir}/hbase-master.jaas"

## Configuration for Local Access

      for nn_ctx in nn_ctxs
        nn_ctx.config.ryba ?= {}
        nn_ctx.config.ryba.hdfs ?= {}
        nn_ctx.config.ryba.hdfs.nn ?= {}
        nn_ctx.config.ryba.hdfs.nn.site ?= {}
        nn_ctx.config.ryba.hdfs.nn.site['dfs.block.local-path-access.user'] ?= ''
        users = nn_ctx.config.ryba.hdfs.nn.site['dfs.block.local-path-access.user'].split(',').filter((str) -> str isnt '')
        users.push 'hbase' unless 'hbase' in users
        nn_ctx.config.ryba.hdfs.nn.site['dfs.block.local-path-access.user'] = users.sort().join ','
      for dn_ctx in dn_ctxs
        dn_ctx.config.ryba ?= {}
        dn_ctx.config.ryba.hdfs ?= {}
        dn_ctx.config.ryba.hdfs.site ?= {}
        dn_ctx.config.ryba.hdfs.site['dfs.block.local-path-access.user'] ?= ''
        users = dn_ctx.config.ryba.hdfs.site['dfs.block.local-path-access.user'].split(',').filter((str) -> str isnt '')
        users.push 'hbase' unless 'hbase' in users
        dn_ctx.config.ryba.hdfs.site['dfs.block.local-path-access.user'] = users.sort().join ','

## Configuration for Log4J


      hbase.master.log4j ?= {}
      hbase.master.log4j[k] ?= v for k, v of @config.log4j
      hbase.master.opts = "#{hbase.master.env['HBASE_MASTER_OPTS']}  -Dhbase.log4j.extra_appender=,socket_server -Dhbase.log4j.server_port=#{hbase.log4j.server_port}" if hbase.log4j?.server_port?
      hbase.master.opts = "#{hbase.master.env['HBASE_MASTER_OPTS']}  -Dhbase.log4j.extra_appender=,socket_client -Dhbase.log4j.remote_host=#{hbase.log4j.remote_host} -Dhbase.log4j.remote_port=#{hbase.log4j.remote_port}" if hbase.log4j?.remote_host? && hbase.log4j?.remote_port?
      #hbase.master.log4j.root_logger = "INFO,RFA,socket_server" if hbase.log4j.server_port?
      #hbase.master.log4j.root_logger = "INFO,RFA,socket_client" if hbase.log4j.remote_host? && hbase.log4j.remote_port?
      #hbase.master.log4j.security_logger = "INFO,RFAS,socket_server" if hbase.log4j.server_port?
      #hbase.master.log4j.security_logger = "INFO,RFAS,socket_client" if hbase.log4j.remote_host? && hbase.log4j.remote_port?

## Configuration for High Availability (HA)

*   [Hortonworks presentation of HBase HA][ha-next-level]
*   [HDP 2.3 Read HA instruction][hdp23]
*   [Bring quorum based write ahead log (write HA)][HBASE-12259]

[ha-next-level]: http://hortonworks.com/blog/apache-hbase-high-availability-next-level/
[hdp23]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.0/bk_hadoop-ha/content/ch_HA-HBase.html
[HBASE-12259]: https://issues.apache.org/jira/browse/HBASE-12259

      if hbase_ctxs.length > 1 # HA enabled
          # StoreFile Refresher
          hbase.master.site['hbase.regionserver.storefile.refresh.all'] ?= 'true'
          # Store File TTL
          hbase.master.site['hbase.regionserver.storefile.refresh.period'] ?= '30000' # Default to '0'
          # Async WAL Replication
          hbase.master.site['hbase.region.replica.replication.enabled'] ?= 'true'
          hbase.master.site['hbase.regionserver.storefile.refresh.all'] ?= 'false'
          # Store File TTL
          hbase.master.site['hbase.master.hfilecleaner.ttl'] ?= '3600000' # 1 hour
          hbase.master.site['hbase.master.loadbalancer.class'] ?= 'org.apache.hadoop.hbase.master.balancer.StochasticLoadBalancer' # Default value
          hbase.master.site['hbase.meta.replica.count'] ?= '3' # Default to '1'
          hbase.master.site['hbase.region.replica.wait.for.primary.flush'] ?= 'true'
          hbase.master.site['hbase.region.replica.storefile.refresh.memstore.multiplier'] ?= '4'

## Configuration Cluster Replication

      hbase.master.site['hbase.replication'] ?= 'true' if hbase.replicated_clusters


## Resources

*   [Tuning G1GC For Your HBase Cluster](https://blogs.apache.org/hbase/entry/tuning_g1gc_for_your_hbase)
*   [HBase: Performance Tunners (read optimization)](http://labs.ericsson.com/blog/hbase-performance-tuners)
*   [Scanning in HBase (read optimization)](http://hadoop-hbase.blogspot.com/2012/01/scanning-in-hbase.html)
*   [Configuring HBase Memstore (write optimization)](http://blog.sematext.com/2012/17/16/hbase-memstore-what-you-should-know/)
*   [Visualizing HBase Flushes and Compactions (write optimization)](http://www.ngdata.com/visiualizing-hbase-flushes-and-compactions/)

[SecureBulkLoadEndpoint]: http://hbase.apache.org/apidocs/org/apache/hadoop/hbase/security/access/SecureBulkLoadEndpoint.html
