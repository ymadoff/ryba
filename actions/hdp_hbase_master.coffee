
lifecycle = require './hdp/lifecycle'
mkcmd = require './hdp/mkcmd'
module.exports = []

module.exports.push 'histi/actions/hdp_hdfs'
module.exports.push 'histi/actions/hdp_zookeeper'
module.exports.push 'histi/actions/hdp_hbase'

module.exports.push (ctx) ->
  require('./hdp_hdfs').configure ctx
  require('./hdp_hbase').configure ctx
  require('./krb5_client').configure ctx

module.exports.push (ctx, next) ->
  {hbase_user} = ctx.config.hdp
  @name 'HDP HBase Master # HDFS layout'
  ctx.log "Create /apps/hbase"
  ctx.execute
    cmd: mkcmd.hdfs ctx, """
    if hadoop fs -ls /apps/hbase &>/dev/null; then exit 3; fi
    hadoop fs -mkdir -p /apps/hbase
    hadoop fs -chown -R #{hbase_user} /apps/hbase
    """
    code_skipped: 3
  , (err, executed, stdout) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP HBase Master # Kerberos'
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  {hadoop_group, hbase_user, hbase_site} = ctx.config.hdp
  ctx.krb5_addprinc
    principal: hbase_site['hbase.master.kerberos.principal'].replace '_HOST', ctx.config.host
    randkey: true
    keytab: hbase_site['hbase.master.keytab.file']
    uid: hbase_user
    gid: hadoop_group
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP HBase Master # Start'
  lifecycle.hbase_master_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS
