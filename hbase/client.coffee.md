
# HBase Client

Install the HBase client package and configure it with secured access.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('./_').configure ctx
      hr_ctxs = ctx.contexts 'ryba/hbase/master', require('./master').configure
      throw Error "No Configured Master" unless hr_ctxs.length
      hbase = ctx.config.ryba.hbase ?= {}
      hbase.site ?= {}
      hbase.site['hbase.security.authentication'] ?= 'kerberos'
      hbase.site['hbase.rpc.engine'] ?= 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
      m_ctxs = ctx.contexts 'ryba/hbase/master'
      hbase.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.regionserver.kerberos.principal']

    module.exports.push commands: 'check', modules: 'ryba/hbase/client_check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/client_install'
