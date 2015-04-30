
# HBase Rest Gateway
Stargate is the name of the REST server bundled with HBase.
The [REST Server](http://wiki.apache.org/hadoop/Hbase/Stargate) is a daemon which enables other application to request HBASE database via http.
Of course we deploy the secured version of the configuration of this API.

    module.exports = []

## Configuration

See [REST Gateway Impersonation Configuration][impersonation].

[impersonation]: http://hbase.apache.org/book.html#security.rest.gateway

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../').configure ctx
      require('../../hadoop/core_ssl').configure ctx
      {realm, core_site, ssl_server, hbase} = ctx.config.ryba
      hbase.site['hbase.rest.port'] ?= '60080' # Default to "8080"
      hbase.site['hbase.rest.info.port'] ?= '60085' # Default to "8085"
      hbase.site['hbase.rest.ssl.enabled'] ?= 'true'
      hbase.site['hbase.rest.ssl.keystore.store'] ?= ssl_server['ssl.server.keystore.location']
      hbase.site['hbase.rest.ssl.keystore.password'] ?= ssl_server['ssl.server.keystore.password']
      hbase.site['hbase.rest.ssl.keystore.keypassword'] ?= ssl_server['ssl.server.keystore.keypassword']
      hbase.site['hbase.rest.kerberos.principal'] ?= "hbase_rest/_HOST@#{realm}" # Dont forget `grant 'rest_server', 'RWCA'`
      hbase.site['hbase.rest.keytab.file'] ?= "#{hbase.conf_dir}/rest.service.keytab"
      hbase.site['hbase.rest.authentication.type'] ?= 'kerberos'
      hbase.site['hbase.rest.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
      # hbase.site['hbase.rest.authentication.kerberos.keytab'] ?= "#{hbase.conf_dir}/hbase.service.keytab"
      hbase.site['hbase.rest.authentication.kerberos.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
      m_ctxs = ctx.contexts 'ryba/hbase/master'
      hbase.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.regionserver.kerberos.principal']

## Commands

    module.exports.push commands: 'check', modules: 'ryba/hbase/rest/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hbase/rest/install'
      'ryba/hbase/rest/start'
      'ryba/hbase/rest/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hbase/rest/start'

    module.exports.push commands: 'status', modules: 'ryba/hbase/rest/status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/rest/stop'
