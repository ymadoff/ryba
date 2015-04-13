
# HBase Client

Install the [HBase client](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/client/package-summary.html) package and configure it with secured access.
you have to use it for administering HBase, create and drop tables, list and alter tables.
Client code accessing a cluster finds the cluster by querying ZooKeeper.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('./_').configure ctx
      hbase = ctx.config.ryba.hbase ?= {}
      hbase.site ?= {}
      hbase.site['hbase.security.authentication'] ?= 'kerberos'
      hbase.site['hbase.rpc.engine'] ?= 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
      [hm_ctx] = ctx.contexts 'ryba/hbase/master', require('./master').configure
      throw Error "No HBase Master" unless hm_ctx
      hbase.site['hbase.master.kerberos.principal'] = hm_ctx.config.ryba.hbase.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.kerberos.principal'] = hm_ctx.config.ryba.hbase.site['hbase.regionserver.kerberos.principal']

## Commands

    module.exports.push commands: 'check', modules: 'ryba/hbase/client_check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/client_install'
