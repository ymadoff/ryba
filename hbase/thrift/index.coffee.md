
# HBase ThriftServer

[Apache Thrift](http://wiki.apache.org/hadoop/Hbase/ThriftApi) is a cross-platform, cross-language development framework.
HBase includes a Thrift API and filter language. The Thrift API relies on client and server processes.
Thrift is both cross-platform and more lightweight than REST for many operations.
From 1.0 thrift can enable impersonation for other service [like hue][hue-hbase-impersonation]
Follows [cloudera hbase setup in secure mode][hbase-configuration]

    module.exports = []

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../').configure ctx
      require('../../hadoop/core_ssl').configure ctx
      {realm, core_site, ssl_server, hbase} = ctx.config.ryba
      hbase.thrift ?= {}
      hbase.thrift.conf_dir ?= '/etc/hbase-thrift/conf'
      hbase.thrift.log_dir ?= '/var/log/hbase'
      hbase.thrift.pid_dir ?= '/var/run/hbase'
      hbase.thrift.site ?= {}
      hbase.thrift.site['hbase.thrift.port'] ?= '9090' # Default to "8080"
      hbase.thrift.site['hbase.thrift.info.port'] ?= '9095' # Default to "8085"
      hbase.thrift.site['hbase.thrift.ssl.enabled'] ?= 'true'
      hbase.thrift.site['hbase.thrift.ssl.keystore.store'] ?= ssl_server['ssl.server.keystore.location']
      hbase.thrift.site['hbase.thrift.ssl.keystore.password'] ?= ssl_server['ssl.server.keystore.password']
      hbase.thrift.site['hbase.thrift.ssl.keystore.keypassword'] ?= ssl_server['ssl.server.keystore.keypassword']
      # Type of HBase thrift server
      hbase.thrift.site['hbase.regionserver.thrift.server.type'] ?= 'TThreadPoolServer'
      # The value for the property hbase.thrift.security.qop can be one of the following values:
      # auth-conf - authentication, integrity, and confidentiality checking
      # auth-int - authentication and integrity checking
      # auth - authentication checking only
      hbase.thrift.site['hbase.thrift.security.qop'] ?= "auth"
      hbase.thrift.env ?= {}
      hbase.thrift.env['JAVA_HOME'] ?= hbase.env['JAVA_HOME']

## Distributed Mode

      properties = [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ]
      for property in properties then hbase.thrift.site[property] ?= hbase.site[property]

## Kerberos

      m_ctxs = ctx.contexts 'ryba/hbase/master'
      hbase.thrift.site['hbase.security.authentication'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authentication']
      hbase.thrift.site['hbase.security.authorization'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authorization']
      hbase.thrift.site['hbase.rpc.engine'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.rpc.engine']
      hbase.thrift.site['hbase.thrift.authentication.type'] = hbase.thrift.site['hbase.security.authentication'] ?= 'kerberos'
      hbase.thrift.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal']
      hbase.thrift.site['hbase.regionserver.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.master.site['hbase.regionserver.kerberos.principal']
            # http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/
      # hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase/_HOST@#{realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      # hbase.site['hbase.thrift.keytab.file'] ?= "#{hbase.conf_dir}/thrift.service.keytab"
      # Principal changed to http by default in order to enable impersonation and make it work with hue
      hbase.thrift.site['hbase.thrift.kerberos.principal'] ?= "HTTP/#{@config.host}@#{realm}" # was hbase_thrift/_HOST
      hbase.thrift.site['hbase.thrift.keytab.file'] ?= core_site['hadoop.http.authentication.kerberos.keytab']

## Impersonation

      # Enables impersonation
      # For now thrift server does not support impersonation for framed transport: check cloudera setup warning
      # http://hbase.apache.org/book.html#security.gateway.thrift
      hbase.thrift.site['hbase.regionserver.thrift.http'] ?= 'true'
      hbase.thrift.site['hbase.thrift.support.proxyuser'] ?= 'true'
      hbase.thrift.site['hbase.regionserver.thrift.framed'] ?= if hbase.thrift.site['hbase.regionserver.thrift.http'] then 'buffered' else 'framed'

## Proxy Users

      hbase_ctxs = ctx.contexts modules: ['ryba/hbase/master', 'ryba/hbase/regionserver']
      for hbase_ctx in hbase_ctxs
        match = /^(.+?)[@\/]/.exec hbase.thrift.site['hbase.thrift.kerberos.principal']
        throw Error 'Invalid HBase Thrift principal' unless match
        hbase_ctx.config.ryba.hbase ?= {}
        hbase_ctx.config.ryba.hbase.master ?= {}
        hbase_ctx.config.ryba.hbase.master.site ?= {}
        hbase_ctx.config.ryba.hbase.master.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase_ctx.config.ryba.hbase.master.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'
        hbase_ctx.config.ryba.hbase.rs ?= {}
        hbase_ctx.config.ryba.hbase.rs.site ?= {}
        hbase_ctx.config.ryba.hbase.rs.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase_ctx.config.ryba.hbase.rs.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'

## Commands

    # module.exports.push commands: 'check', modules: 'ryba/hbase/thrift/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hbase/thrift/install'
      'ryba/hbase/thrift/start'
      'ryba/hbase/thrift/check'
    ]

    module.exports.push commands: 'check', modules: 'ryba/hbase/thrift/check'
    module.exports.push commands: 'start', modules: 'ryba/hbase/thrift/start'

    module.exports.push commands: 'status', modules: 'ryba/hbase/thrift/status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/thrift/stop'

  [hue-hbase-impersonation]:(http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/)
  [hbase-configuration]:(http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_sg_hbase_authentication.html/)
