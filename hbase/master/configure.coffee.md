
## Configuration

    module.exports = handler: ->
      # if ctx.hbase_master_configured then return else ctx.hbase_master_configured = null
      # require('../../lib/hconfigure').call ctx
      # require('../../libmodule.exports.push 'ryba/lib/hdp_select'').call ctx
      # require('../../lib/write_jaas').call ctx
      # require('../../ganglia/collector').configure ctx
      # require('../../graphite/carbon').configure ctx
      # require('../../hadoop/hdfs').configure ctx
      # require('../').configure ctx
      require('../lib/configure_metrics.coffee.md').call
      require('../common/configure').handler.call @
      {realm, hbase, ganglia, graphite} = @config.ryba
      {java_home} = @config.java
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

      for property in [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then hbase.master.site[property] ?= hbase.site[property]

## Configuration for Kerberos

      hbase.master.site['hbase.security.authentication'] ?=  hbase.site['hbase.security.authentication'] # Required by HM, RS and client
      hbase.master.site['hbase.master.keytab.file'] ?= '/etc/security/keytabs/hm.service.keytab'
      hbase.master.site['hbase.master.kerberos.principal'] ?= hbase.site['hbase.master.kerberos.principal'] # was "hbase/_HOST@#{realm}"
      hbase.master.site['hbase.regionserver.kerberos.principal'] ?= hbase.site['hbase.regionserver.kerberos.principal'] # "hbase/_HOST@#{realm}"
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

      hbase.master.site['hbase.security.authorization'] ?= hbase.site['hbase.security.authorization'] 
      hbase.master.site['hbase.rpc.engine'] ?= hbase.site['org.apache.hadoop.hbase.ipc.SecureRpcEngine']
      hbase.master.site['hbase.superuser'] ?= hbase.admin.name
      hbase.master.site['hbase.bulkload.staging.dir'] ?= '/apps/hbase/staging'
      hbase.master.opts ?= "-Xmx2048m "
      if hbase.master.opts.indexOf('-Djava.security.auth.login.config') is -1
        hbase.master.opts += " -Djava.security.auth.login.config=#{hbase.master.conf_dir}/hbase-master.jaas"
       

## Configuration for Proxy Users

      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hbase.user.name}.hosts"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hbase.user.name}.groups"] ?= '*'

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

      if @contexts('ryba/hbase/master').length > 1 # HA enabled
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
