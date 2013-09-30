
hdp_hbase = require './hdp_hbase'
module.exports = []

module.exports.push module.exports.configure = (ctx) ->
  hdp_hbase.configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP HBase # Kerberos'
  {realm} = ctx.config.krb5_client
  ctx.mkprincipal
    principal: "hbase/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/hbase.service.keytab"
    uid: 'hbase'
    gid: 'hadoop'
    not_if_exists: "/etc/security/keytabs/hbase.service.keytab"
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS