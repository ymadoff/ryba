
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
      hbase.site['hbase.thrift.port'] ?= '9090' # Default to "8080"
      hbase.site['hbase.thrift.info.port'] ?= '9095' # Default to "8085"
      hbase.site['hbase.thrift.ssl.enabled'] ?= 'true'
      hbase.site['hbase.thrift.ssl.keystore.store'] ?= ssl_server['ssl.server.keystore.location']
      hbase.site['hbase.thrift.ssl.keystore.password'] ?= ssl_server['ssl.server.keystore.password']
      hbase.site['hbase.thrift.ssl.keystore.keypassword'] ?= ssl_server['ssl.server.keystore.keypassword']
      hbase.site['hbase.thrift.authentication.type'] ?= 'kerberos'
      # hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase/_HOST@#{realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      # hbase.site['hbase.thrift.keytab.file'] ?= "#{hbase.conf_dir}/thrift.service.keytab"
      # Principal changed to http by default in order to enable impersonation and make it work with hue
      # http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/
      hbase.site['hbase.thrift.kerberos.principal'] ?= "HTTP/#{@config.host}@#{realm}" # was hbase_thrift/_HOST
      hbase.site['hbase.thrift.keytab.file'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
      hbase.site['hbase.regionserver.thrift.framed'] ?= 'buffered'
      # Enables impersonation
      # http://hbase.apache.org/book.html#security.client.thrift
      # For now thrift server does not support impersonation for framed transport: check cloudera setup warning
      if hbase.site['hbase.thrift.kerberos.principal'].indexOf 'HTTP' > -1 and hbase.site['hbase.regionserver.thrift.framed'] != 'framed'
        hbase.site['hbase.regionserver.thrift.http'] ?= 'true'
        hbase.site['hbase.thrift.support.proxyuser'] ?= 'true'
      # Type of HBase thrift server
      hbase.site['hbase.regionserver.thrift.server.type'] ?= 'TThreadPoolServer'
      # The value for the property hbase.thrift.security.qop can be one of the following values:
      # auth-conf - authentication, integrity, and confidentiality checking
      # auth-int - authentication and integrity checking
      # auth - authentication checking only
      hbase.site['hbase.thrift.security.qop'] ?= "auth"
      m_ctxs = ctx.contexts 'ryba/hbase/master'
      hbase.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.regionserver.kerberos.principal']

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
