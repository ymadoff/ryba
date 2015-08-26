
# HBase ThriftServer

[Apache Thrift](http://wiki.apache.org/hadoop/Hbase/ThriftApi) is a cross-platform, cross-language development framework.
HBase includes a Thrift API and filter language. The Thrift API relies on client and server processes.
Thrift is both cross-platform and more lightweight than REST for many operations.

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
      hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase_thrift/_HOST@#{realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      hbase.site['hbase.thrift.keytab.file'] ?= "#{hbase.conf_dir}/thrift.service.keytab"
      hbase.site['hbase.thrift.authentication.type'] ?= 'kerberos'
      hbase.site['hbase.thrift.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
      # hbase.site['hbase.thrift.authentication.kerberos.keytab'] ?= "#{hbase.conf_dir}/hbase.service.keytab"
      hbase.site['hbase.thrift.authentication.kerberos.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
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

    module.exports.push commands: 'start', modules: 'ryba/hbase/thrift/start'

    module.exports.push commands: 'status', modules: 'ryba/hbase/thrift/status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/thrift/stop'
