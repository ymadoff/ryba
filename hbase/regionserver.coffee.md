
# HBase RegionServer

    module.exports = []
    
## Configuration

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx
      {realm, hbase} = ctx.config.ryba
      hr_ctxs = ctx.contexts 'ryba/hbase/master', require('./master').configure
      throw Error "No Configured Master" unless hr_ctxs.length
      hbase.site['hbase.regionserver.port'] ?= '60020'
      hbase.site['hbase.regionserver.info.port'] ?= '60030'
      hbase.site['hadoop.ssl.enabled'] ?= 'true'
    
## Configuration for Kerberos

      hbase.site['hbase.master.kerberos.principal'] = hr_ctxs[0].config.ryba.hbase.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.keytab.file'] ?= "#{hbase.conf_dir}/rs.service.keytab" # was rs.service.keytab
      hbase.site['hbase.regionserver.kerberos.principal'] ?= "hbase/_HOST@#{realm}"

## Proxy Users

      thrift_ctxs = ctx.contexts 'ryba/hbase/thrift', require('./thrift').configure
      if thrift_ctxs.length
        principal = thrift_ctxs[0].config.ryba.hbase.site['hbase.thrift.kerberos.principal']
        throw Error 'Invalid HBase Thrift principal' unless match = /^(.+?)[@\/]/.exec principal
        hbase.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'
      rest_ctxs = ctx.contexts 'ryba/hbase/rest', require('./rest').configure
      if rest_ctxs.length
        principal = rest_ctxs[0].config.ryba.hbase.site['hbase.rest.kerberos.principal']
        throw Error 'Invalid HBase Rest principal' unless match = /^(.+?)[@\/]/.exec principal
        hbase.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/regionserver_backup'

    module.exports.push commands: 'check', modules: 'ryba/hbase/regionserver_check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/regionserver_install'

    module.exports.push commands: 'start', modules: 'ryba/hbase/regionserver_start'

    module.exports.push commands: 'status', modules: 'ryba/hbase/regionserver_status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/regionserver_stop'
