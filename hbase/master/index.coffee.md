
# HBase Master
[HMaster](http://hbase.apache.org/book.html#_master) is the implementation of the Master Server.
The Master server is responsible for monitoring all RegionServer instances in the cluster, and is the interface for all metadata changes.
In a distributed cluster, the Master typically runs on the NameNode.
J Mohamed Zahoor goes into some more detail on the Master Architecture in this blog posting, [HBase HMaster Architecture](http://blog.zahoor.in/2012/08/hbase-hmaster-architecture/)

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      if ctx.hbase_master_configured then return else ctx.hbase_master_configured = null
      require('masson/core/iptables').configure ctx
      # require('../../hadoop/hdfs').configure ctx
      require('../').configure ctx
      {realm, hbase} = ctx.config.ryba
      hbase.admin ?= {}
      hbase.admin.principal ?= "#{hbase.site['hbase.superuser']}@#{realm}"
      hbase.admin.password ?= "hbase123"
      hbase.master_opts ?= ''
      hbase.site['hbase.master.port'] ?= '60000'
      hbase.site['hbase.master.info.port'] ?= '60010'
      hbase.site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
      hbase.site['hadoop.ssl.enabled'] ?= 'true'

## Configuration for Kerberos

      hbase.site['hbase.master.keytab.file'] ?= "#{hbase.conf_dir}/hm.service.keytab" # was hm.service.keytab
      hbase.site['hbase.master.kerberos.principal'] ?= "hbase/_HOST@#{realm}"
      hbase.site['hbase.regionserver.kerberos.principal'] ?= "hbase/_HOST@#{realm}"
      hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.hadoop.hbase.security.access.AccessController'

## Proxy Users

      thrift_ctxs = ctx.contexts 'ryba/hbase/thrift', require('../thrift').configure
      if thrift_ctxs.length
        principal = thrift_ctxs[0].config.ryba.hbase.site['hbase.thrift.kerberos.principal']
        throw Error 'Invalid HBase Thrift principal' unless match = /^(.+?)[@\/]/.exec principal
        hbase.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'
      rest_ctxs = ctx.contexts 'ryba/hbase/rest', require('../rest').configure
      if rest_ctxs.length
        principal = rest_ctxs[0].config.ryba.hbase.site['hbase.rest.kerberos.principal']
        throw Error 'Invalid HBase Rest principal' unless match = /^(.+?)[@\/]/.exec principal
        hbase.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'

## Highly Available Reads with HBase

*   [Hortonworks presentation of HBase HA][ha-next-level]
*   [HDP 2.2 Read HA instruction][hdp22]
*   [Bring quorum based write ahead log (write HA)][HBASE-12259]

[ha-next-level]: http://hortonworks.com/blog/apache-hbase-high-availability-next-level/
[hdp22]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/Hadoop_HA_v22/ha_hbase_reads/index.html#Item1.1.5
[HBASE-12259]: https://issues.apache.org/jira/browse/HBASE-12259

      # # StoreFile Refresher
      # hbase.site['hbase.regionserver.storefile.refresh.all'] ?= 'true'
      # # Async WAL Replication
      # # hbase.site['hbase.region.replica.replication.enabled] ?= 'true'
      # # hbase.site['hbase.regionserver.storefile.refresh.all'] ?= 'false'
      # # Store File TTL
      # hbase.site['hbase.regionserver.storefile.refresh.period'] ?= '30000' # Default to '0'
      # hbase.site['hbase.master.hfilecleaner.ttl'] ?= '3600000' # 1 hour
      # hbase.site['hbase.master.loadbalancer.class'] ?= 'org.apache.hadoop.hbase.master.balancer.StochasticLoadBalancer' # Default value
      # hbase.site['hbase.meta.replica.count'] ?= '3' # Default to '1'
      # hbase.site['hbase.region.replica.wait.for.primary.flush'] ?= 'true'
      # hbase.site['hbase.region.replica.storefile.refresh.memstore.multiplier'] ?= '4'

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/master/backup'

    module.exports.push commands: 'check', modules: 'ryba/hbase/master/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hbase/master/install'
      'ryba/hbase/master/start'
      'ryba/hbase/master/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hbase/master/start'

    # module.exports.push commands: 'status', modules: 'ryba/hbase/master/status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/master/stop'
