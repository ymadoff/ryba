
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
      require('../../ganglia/collector').configure ctx
      require('../../graphite/carbon').configure ctx
      # require('../../hadoop/hdfs').configure ctx
      require('../').configure ctx
      {realm, hbase, ganglia, graphite} = ctx.config.ryba
      hbase.master_opts ?= hbase.env['HBASE_MASTER_OPTS']
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

## Configuration for Log4J

      hbase.master_opts = "#{hbase.env['HBASE_MASTER_OPTS']} -Dhbase.log4j.extra_appender=,socket_server -Dhbase.log4j.server_port=#{hbase.log4j.server_port}" if hbase.log4j?.server_port?
      hbase.master_opts = "#{hbase.env['HBASE_MASTER_OPTS']} -Dhbase.log4j.extra_appender=,socket_client -Dhbase.log4j.remote_host=#{hbase.log4j.remote_host} -Dhbase.log4j.remote_port=#{hbase.log4j.remote_port}" if hbase.log4j?.remote_host? && hbase.log4j?.remote_port?
      #hbase.master.log4j.root_logger = "INFO,RFA,socket_server" if hbase.log4j.server_port?
      #hbase.master.log4j.root_logger = "INFO,RFA,socket_client" if hbase.log4j.remote_host? && hbase.log4j.remote_port?
      #hbase.master.log4j.security_logger = "INFO,RFAS,socket_server" if hbase.log4j.server_port?
      #hbase.master.log4j.security_logger = "INFO,RFAS,socket_client" if hbase.log4j.remote_host? && hbase.log4j.remote_port?

## Metrics systems

      metrics_sinks = []
      ganglia_host =  ctx.host_with_module 'ryba/ganglia/collector'
      graphite_host = ctx.host_with_module 'ryba/graphite/carbon'
      if ganglia_host
        ganglia_hbase_port = ganglia.hbase_master_port
        metrics_sinks.push
          name: 'ganglia'
          properties: {class: 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31', period: '10', servers: "#{ganglia_host}:#{ganglia_hbase_port}", metrics_prefix: ''}
      if graphite_host
        graphite_port = graphite.carbon_aggregator_port
        metrics_prefix = "#{graphite.metrics_prefix}.hbase"
        metrics_sinks.push
          name: 'graphite'
          properties: {class: 'org.apache.hadoop.metrics2.sink.GraphiteSink', period: '10', server_host: graphite_host, server_port: graphite_port , metrics_prefix: metrics_prefix}
      hbase.metrics ?= {}
      hbase.metrics['hbase.extendedperiod'] ?= '3600'
      for sink in metrics_sinks
        for context in ['hbase','jvm','rpc']
          for k,v of sink.properties
            hbase.metrics["#{context}.sink.#{sink.name}.#{k}"] = v

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
