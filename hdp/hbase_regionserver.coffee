
lifecycle = require './lib/lifecycle'
module.exports = []
module.exports.push 'phyla/bootstrap'
module.exports.push 'phyla/hdp/hdfs'
module.exports.push 'phyla/hdp/zookeeper'
module.exports.push 'phyla/hdp/hbase'

module.exports.push (ctx) ->
  require('./hdfs').configure
  require('./hbase').configure

module.exports.push name: 'HDP HBase RegionServer # Kerberos', timeout: -1, callback: (ctx, next) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  {hadoop_group, hbase_user, hbase_site} = ctx.config.hdp
  ctx.krb5_addprinc
    principal: hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', ctx.config.host
    randkey: true
    keytab: hbase_site['hbase.regionserver.keytab.file']
    uid: hbase_user
    gid: hadoop_group
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HBase RegionServer # Start', callback: (ctx, next) ->
  lifecycle.hbase_regionserver_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS