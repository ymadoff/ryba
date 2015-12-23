
# HBase RegionServer
[HRegionServer](http://hbase.apache.org/book.html#regionserver.arch) is the RegionServer implementation.
It is responsible for serving and managing regions. In a distributed cluster, a RegionServer runs on a DataNode.

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../../ganglia/collector').configure ctx
      require('../../graphite/carbon').configure ctx
      require('../../hadoop/hdfs').configure ctx
      require('../').configure ctx
      require('../lib/configure_metrics.coffee.md').call ctx
      {realm, hbase, ganglia, graphite} = ctx.config.ryba
      m_ctxs = ctx.contexts 'ryba/hbase/master', require('../master').configure
      throw Error "No Configured Master" unless m_ctxs.length
      hbase.site['hbase.regionserver.port'] ?= '60020'
      hbase.site['hbase.regionserver.info.port'] ?= '60030'
      hbase.site['hbase.ssl.enabled'] ?= 'true'
      hbase.site['hbase.regionserver.handler.count'] ?= 60 # HDP default
      # http://blog.sematext.com/2012/07/16/hbase-memstore-what-you-should-know/
      # Keep hbase.regionserver.hlog.blocksize * hbase.regionserver.maxlogs just
      # a bit above hbase.regionserver.global.memstore.lowerLimit * HBASE_HEAPSIZE

      hbase.regionserver_opts ?= ''

## Configuration for Kerberos

      hbase.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.master.kerberos.principal'] #.replace '_HOST', m_ctxs[0].config.host
      hbase.site['hbase.regionserver.keytab.file'] ?= '/etc/security/keytabs/rs.service.keytab'
      hbase.site['hbase.regionserver.kerberos.principal'] ?= m_ctxs[0].config.ryba.hbase.site['hbase.regionserver.kerberos.principal']
      hbase.site['hbase.regionserver.global.memstore.upperLimit'] = null # Deprecated from HDP 2.3
      hbase.site['hbase.regionserver.global.memstore.size'] = '0.4' # Default in HDP Companion Files
      hbase.site['hbase.coprocessor.region.classes'] ?= [
        'org.apache.hadoop.hbase.security.token.TokenProvider'
        'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint'
        'org.apache.hadoop.hbase.security.access.AccessController'
      ]

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

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/regionserver/backup'

    module.exports.push commands: 'check', modules: 'ryba/hbase/regionserver/check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/regionserver/install'

    module.exports.push commands: 'start', modules: 'ryba/hbase/regionserver/start'

    module.exports.push commands: 'status', modules: 'ryba/hbase/regionserver/status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/regionserver/stop'
