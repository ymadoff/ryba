
# HBase Client

Install the HBase client package and configure it with secured access.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('./_').configure ctx
      hbase_site = ctx.config.ryba.hbase_site ?= {}
      hbase_site['hbase.security.authentication'] ?= 'kerberos'
      hbase_site['hbase.rpc.engine'] ?= 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
      ctx.config.ryba.shortname ?= ctx.config.shortname or ctx.config.host.split('.')[0]

    module.exports.push commands: 'check', modules: 'ryba/hbase/client_check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/client_install'





