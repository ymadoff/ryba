
# HBase Master
[HMaster](http://hbase.apache.org/book.html#_master) is the implementation of the Master Server.
The Master server is responsible for monitoring all RegionServer instances in the cluster, and is the interface for all metadata changes.
In a distributed cluster, the Master typically runs on the NameNode.
J Mohamed Zahoor goes into some more detail on the Master Architecture in this blog posting, [HBase HMaster Architecture](http://blog.zahoor.in/2012/08/hbase-hmaster-architecture/)

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      if ctx.hbase_master_configured then return else ctx.hbase_master_configured = null
      # require('../../lib/hconfigure').call ctx
      # require('../../libmodule.exports.push 'ryba/lib/hdp_select'').call ctx
      # require('../../lib/write_jaas').call ctx
      require('masson/core/iptables').configure ctx
      # require('../../ganglia/collector').configure ctx
      # require('../../graphite/carbon').configure ctx
      # require('../../hadoop/hdfs').configure ctx
      require('../').configure ctx
      require('../lib/configure_metrics.coffee.md').call ctx
      {realm, hbase, ganglia, graphite} = ctx.config.ryba
      hbase.master_opts ?= hbase.env['HBASE_MASTER_OPTS']
      hbase.site['hbase.master.port'] ?= '60000'
      hbase.site['hbase.master.info.port'] ?= '60010'
      hbase.site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
      hbase.site['hbase.ssl.enabled'] ?= 'true'

## Configuration for Kerberos

      hbase.site['hbase.master.keytab.file'] ?= "#{hbase.conf_dir}/hm.service.keytab" # was hm.service.keytab
      hbase.site['hbase.master.kerberos.principal'] ?= "hbase/_HOST@#{realm}"
      hbase.site['hbase.regionserver.kerberos.principal'] ?= "hbase/_HOST@#{realm}"
      hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.hadoop.hbase.security.access.AccessController'

## Configuration for Proxy Users

      hadoop_ctxs = ctx.contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hbase.user.name}.hosts"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hbase.user.name}.groups"] ?= '*'

## Configuration for Log4J

      hbase.master_opts = "#{hbase.env['HBASE_MASTER_OPTS']} -Dhbase.log4j.extra_appender=,socket_server -Dhbase.log4j.server_port=#{hbase.log4j.server_port}" if hbase.log4j?.server_port?
      hbase.master_opts = "#{hbase.env['HBASE_MASTER_OPTS']} -Dhbase.log4j.extra_appender=,socket_client -Dhbase.log4j.remote_host=#{hbase.log4j.remote_host} -Dhbase.log4j.remote_port=#{hbase.log4j.remote_port}" if hbase.log4j?.remote_host? && hbase.log4j?.remote_port?
      #hbase.master.log4j.root_logger = "INFO,RFA,socket_server" if hbase.log4j.server_port?
      #hbase.master.log4j.root_logger = "INFO,RFA,socket_client" if hbase.log4j.remote_host? && hbase.log4j.remote_port?
      #hbase.master.log4j.security_logger = "INFO,RFAS,socket_server" if hbase.log4j.server_port?
      #hbase.master.log4j.security_logger = "INFO,RFAS,socket_client" if hbase.log4j.remote_host? && hbase.log4j.remote_port?

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/master/backup'

    module.exports.push commands: 'check', modules: 'ryba/hbase/master/check'

    module.exports.push commands: 'install', modules: [
      'masson/bootstrap'
      'masson/core/iptables'
      'ryba/hadoop/hdfs'
      'ryba/hbase'
      'ryba/lib/hconfigure'
      'ryba/lib/hdp_select'
      'ryba/lib/write_jaas'
      'ryba/hbase/master/install'
      'ryba/hadoop/hdfs_nn/wait'
      'ryba/hbase/master/layout'
      'ryba/hbase/master/start'
      'ryba/hbase/master/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hbase/master/start'

    # module.exports.push commands: 'status', modules: 'ryba/hbase/master/status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/master/stop'
